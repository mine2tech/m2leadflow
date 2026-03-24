class OutboundMailer < ApplicationMailer
  def cold_email(draft)
    @draft = draft
    @contact = draft.contact

    mail(
      to: @contact.email,
      subject: @draft.subject
    )
  end
end
