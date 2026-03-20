module TaskResultProcessors
  class DraftEmail
    def self.call(task)
      contact = Contact.find(task.payload["contact_id"])
      is_followup = task.payload["is_followup"]
      seq = task.payload["sequence_number"]

      draft = Draft.new(
        contact: contact,
        subject: task.result["subject"],
        body: task.result["body"],
        status: :draft,
        sequence_number: seq || (is_followup ? nil : 1)
      )

      if is_followup
        draft.email_thread = contact.email_threads.order(:created_at).first
      end

      draft.save!
    end
  end
end
