class GmailSendingService
  def self.call(draft, sent_by: nil)
    new(draft, sent_by: sent_by).call
  end

  def initialize(draft, sent_by: nil)
    @draft = draft
    @contact = draft.contact
    @sent_by = sent_by
    @account = GmailAccount.active.first
    raise "No active Gmail account configured. Add one in Settings." unless @account
  end

  def call
    raise "Contact has no email address. Add an email before sending." if @contact.email.blank?
    refresh_token_if_needed!

    message = build_mime_message
    gmail_message = Google::Apis::GmailV1::Message.new

    # Thread replies: set threadId so Gmail groups them
    if @draft.email_thread&.external_thread_id.present?
      gmail_message.thread_id = @draft.email_thread.external_thread_id
    end

    result = @service.send_user_message(
      "me",
      gmail_message,
      upload_source: StringIO.new(message.to_s),
      content_type: "message/rfc822"
    )

    # Create/update thread and message records
    thread = find_or_create_thread(result)
    @draft.update!(email_thread: thread) unless @draft.email_thread_id

    thread.messages.create!(
      direction: :outbound,
      subject: @draft.subject,
      body: @draft.body,
      gmail_message_id: result.id
    )

    @draft.update!(status: :sent)

    if (followup = @draft.followup)
      followup.update!(status: :completed)
    end

    ActivityTracker.track(@contact, action: "email_sent", user: @sent_by, metadata: {
      draft_id: @draft.id, subject: @draft.subject
    })

    result
  end

  private

  def build_mime_message
    mail = Mail.new
    mail.to = @contact.email
    mail.from = @account.email
    mail.subject = @draft.subject

    # Thread reply headers
    if @draft.email_thread.present?
      last_msg = @draft.email_thread.messages.order(:created_at).last
      if last_msg&.gmail_message_id.present?
        mail.in_reply_to = "<#{last_msg.gmail_message_id}>"
        mail.references = "<#{last_msg.gmail_message_id}>"
      end
    end

    text_part = Mail::Part.new(body: @draft.body, content_type: "text/plain; charset=UTF-8")
    html_part = Mail::Part.new(
      body: simple_format_html(@draft.body),
      content_type: "text/html; charset=UTF-8"
    )

    if @draft.attachments.any?
      # Build multipart/mixed with nested multipart/alternative for body
      alt_part = Mail::Part.new(content_type: "multipart/alternative")
      alt_part.add_part(text_part)
      alt_part.add_part(html_part)
      mail.add_part(alt_part)

      @draft.attachments.each do |attachment|
        mail.add_file(
          filename: attachment.filename.to_s,
          content: attachment.download
        )
      rescue StandardError => e
        Rails.logger.error("GmailSendingService: Failed to attach #{attachment.filename}: #{e.message}")
      end
    else
      mail.text_part = text_part
      mail.html_part = html_part
    end

    mail
  end

  def find_or_create_thread(result)
    if @draft.email_thread.present?
      thread = @draft.email_thread
      thread.update!(external_thread_id: result.thread_id) if thread.external_thread_id.blank?
      thread
    else
      @contact.email_threads.create!(external_thread_id: result.thread_id)
    end
  end

  def refresh_token_if_needed!
    @service = Google::Apis::GmailV1::GmailService.new
    client = Signet::OAuth2::Client.new(
      client_id: ENV["GMAIL_CLIENT_ID"],
      client_secret: ENV["GMAIL_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @account.access_token,
      refresh_token: @account.refresh_token,
      expires_at: @account.token_expires_at
    )

    if @account.token_expired?
      client.fetch_access_token!
      @account.update!(
        access_token: client.access_token,
        token_expires_at: Time.current + client.expires_in.to_i.seconds,
        status: :active
      )
    end

    @service.authorization = client
  end

  def simple_format_html(text)
    escaped = ERB::Util.html_escape(text)
    "<html><body>#{escaped.gsub("\n", "<br>")}</body></html>"
  end
end
