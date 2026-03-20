class EmailSendingService
  def self.call(draft)
    new(draft).call
  end

  def initialize(draft)
    @draft = draft
    @contact = draft.contact
  end

  def call
    message = OutboundMailer.cold_email(@draft).deliver_now

    thread = @contact.email_threads.order(:created_at).first ||
             @contact.email_threads.create!
    @draft.update!(email_thread: thread)

    thread.messages.create!(
      direction: :outbound,
      subject: @draft.subject,
      body: @draft.body,
      gmail_message_id: message.message_id
    )

    @draft.update!(status: :sent)

    if (followup = @draft.followup)
      followup.update!(status: :completed)
    end
  end
end
