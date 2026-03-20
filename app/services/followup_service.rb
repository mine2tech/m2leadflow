class FollowupService
  def self.check_and_create
    delay_days = Setting.followup_delay_days
    max_followups = Setting.max_followups

    Contact.find_each do |contact|
      next if contact.has_reply?
      next unless contact.last_outbound_at
      next if contact.last_outbound_at > delay_days.days.ago
      next if contact.followup_count >= max_followups

      sequence = contact.followup_count + 1

      next if contact.followups.pending.where(sequence_number: sequence).exists?

      followup = contact.followups.create!(
        scheduled_at: Time.current,
        status: :pending,
        delay_days: delay_days,
        sequence_number: sequence
      )

      if Setting.followup_use_ai?
        Task.create!(
          task_type: "draft_email",
          payload: {
            contact_id: contact.id,
            company_context: contact.company.slice(:name, :domain, :notes),
            contact: { name: contact.name, role: contact.role },
            is_followup: true,
            sequence_number: sequence
          }
        )
      else
        draft = Draft.create!(
          contact: contact,
          subject: "Following up",
          body: default_followup_template(contact, sequence),
          status: Setting.auto_send_followups? ? :approved : :draft
        )
        followup.update!(draft: draft)

        if Setting.auto_send_followups? && draft.approved?
          EmailSendingService.call(draft)
        end
      end
    end
  end

  def self.default_followup_template(contact, sequence)
    name = contact.name&.split(" ")&.first || "there"
    "Hi #{name},\n\nJust wanted to follow up on my previous email. " \
    "Would love to connect if you have a few minutes.\n\nBest regards"
  end
end
