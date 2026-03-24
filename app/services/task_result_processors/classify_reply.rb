module TaskResultProcessors
  class ClassifyReply
    VALID_CLASSIFICATIONS = %w[interested not_interested out_of_office wrong_person auto_reply].freeze

    def self.call(task)
      message = Message.find(task.payload["message_id"])
      contact = Contact.find(task.payload["contact_id"])
      thread = EmailThread.find(task.payload["thread_id"])

      classification = task.result["classification"]
      raise ArgumentError, "Invalid classification: #{classification}" unless VALID_CLASSIFICATIONS.include?(classification)

      confidence = task.result["confidence"]&.to_f || 0.8
      message.update!(classification: classification, classification_confidence: confidence)

      case classification
      when "interested"
        handle_interested(task, contact, thread)
      when "not_interested"
        handle_not_interested(contact)
      when "out_of_office"
        handle_out_of_office(task, contact)
      end

      ActivityTracker.track(contact, action: "reply_classified", metadata: {
        message_id: message.id,
        classification: classification,
        confidence: confidence
      })
    end

    def self.handle_interested(task, contact, thread)
      return unless task.result["suggested_reply"].present?

      first_subject = thread.messages.order(:created_at).first&.subject
      Draft.create!(
        contact: contact,
        email_thread: thread,
        subject: task.result["suggested_subject"] || "Re: #{first_subject}",
        body: task.result["suggested_reply"],
        status: :draft
      )
    end

    def self.handle_not_interested(contact)
      contact.followups.where(status: :pending).update_all(status: :skipped)
    end

    def self.handle_out_of_office(task, contact)
      snooze_days = task.result["snooze_days"]&.to_i || 7
      contact.followups.where(status: :pending).find_each do |followup|
        new_date = [followup.scheduled_at, Time.current].max + snooze_days.days
        followup.update!(scheduled_at: new_date)
      end
    end

    private_class_method :handle_interested, :handle_not_interested, :handle_out_of_office
  end
end
