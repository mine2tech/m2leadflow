module TaskResultProcessors
  class DraftEmail
    def self.call(task)
      contact = Contact.find(task.payload["contact_id"])
      is_followup = task.payload["is_followup"]
      seq = task.payload["sequence_number"]

      subject = task.result["subject"].presence
      body = task.result["body"].presence
      raise ArgumentError, "Missing subject or body in task result" if subject.nil? || body.nil?

      draft = Draft.new(
        contact: contact,
        subject: subject,
        body: body,
        status: :draft,
        sequence_number: seq || (is_followup ? nil : 1)
      )

      if is_followup
        thread = contact.email_threads.order(:created_at).first
        draft.email_thread = thread if thread
      end

      draft.save!
    end
  end
end
