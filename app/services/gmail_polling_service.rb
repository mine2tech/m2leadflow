class GmailPollingService
  def self.call
    GmailAccount.active.find_each do |account|
      new(account).poll
    rescue StandardError => e
      Rails.logger.error("Gmail polling failed for #{account.email}: #{e.message}")
    end
  end

  def initialize(account)
    @account = account
    @service = build_service
  end

  def poll
    refresh_token_if_needed!

    response = @service.list_user_messages(
      "me",
      q: "is:inbox newer_than:5m",
      max_results: 50
    )

    return unless response.messages

    response.messages.each do |msg_ref|
      process_message(msg_ref.id)
    rescue StandardError => e
      Rails.logger.error("Failed to process message #{msg_ref.id}: #{e.message}")
    end
  end

  private

  def process_message(message_id)
    return if Message.exists?(gmail_message_id: message_id)

    msg = @service.get_user_message("me", message_id, format: "full")

    headers = (msg.payload.headers || []).index_by(&:name)
    in_reply_to = headers["In-Reply-To"]&.value
    references = (headers["References"]&.value || "").split(/\s+/)
    subject = headers["Subject"]&.value

    all_refs = ([in_reply_to] + references).compact.uniq
    outbound_message = Message.where(gmail_message_id: all_refs).first
    return unless outbound_message

    thread = outbound_message.email_thread

    inbound_message = thread.messages.create!(
      direction: :inbound,
      subject: subject,
      body: extract_body(msg),
      gmail_message_id: message_id
    )

    thread.update!(external_thread_id: msg.thread_id) if thread.external_thread_id.blank?

    # Track activity and notify
    contact = thread.contact
    ActivityTracker.track(contact, action: "reply_received", metadata: { subject: subject })
    SlackNotificationService.reply_received(inbound_message) if Setting.slack_webhook_url.present?

    Rails.logger.info("Matched inbound reply to thread #{thread.id}")
  end

  def extract_body(msg)
    if msg.payload.parts
      text_part = msg.payload.parts.find { |p| p.mime_type == "text/plain" }
      return Base64.urlsafe_decode64(text_part.body.data) if text_part&.body&.data
    end
    msg.snippet
  end

  def build_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = build_client
    service
  end

  def build_client
    Signet::OAuth2::Client.new(
      client_id: ENV["GMAIL_CLIENT_ID"],
      client_secret: ENV["GMAIL_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @account.access_token,
      refresh_token: @account.refresh_token,
      expires_at: @account.token_expires_at
    )
  end

  def refresh_token_if_needed!
    return unless @account.token_expired?

    client = build_client
    client.fetch_access_token!

    @account.update!(
      access_token: client.access_token,
      token_expires_at: Time.current + client.expires_in.to_i.seconds,
      status: :active
    )

    @service.authorization = client
  rescue StandardError => e
    @account.update!(status: :expired)
    raise e
  end
end
