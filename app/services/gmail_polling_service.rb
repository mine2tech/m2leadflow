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
      q: "is:inbox newer_than:1h",
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
    subject = headers["Subject"]&.value
    from = headers["From"]&.value

    # Skip messages sent by us (outbound)
    return if from&.include?(@account.email)

    # Match by Gmail thread ID — most reliable way to link replies
    thread = EmailThread.find_by(external_thread_id: msg.thread_id)
    return unless thread

    inbound_message = thread.messages.create!(
      direction: :inbound,
      subject: subject,
      body: extract_body(msg),
      gmail_message_id: message_id
    )

    # Track activity and notify
    contact = thread.contact
    ActivityTracker.track(contact, action: "reply_received", metadata: { subject: subject })
    SlackNotificationService.reply_received(inbound_message) if Setting.slack_webhook_url.present?

    # Create classify_reply task for AI agent
    previous_outbound = thread.messages.where(direction: :outbound).order(:created_at).last
    Task.create!(
      task_type: "classify_reply",
      payload: {
        message_id: inbound_message.id,
        contact_id: contact.id,
        thread_id: thread.id,
        reply_body: inbound_message.body&.truncate(2000),
        reply_subject: subject,
        contact_name: contact.name,
        contact_role: contact.role,
        company_name: contact.company&.name,
        previous_outbound: previous_outbound&.body&.truncate(1000)
      }
    )

    Rails.logger.info("Matched inbound reply to thread #{thread.id}")
  end

  def extract_body(msg)
    if msg.payload.parts
      text_part = find_text_part(msg.payload.parts)
      return decode_body_data(text_part.body.data) if text_part&.body&.data
    elsif msg.payload.body&.data
      return decode_body_data(msg.payload.body.data)
    end
    msg.snippet
  end

  def find_text_part(parts)
    parts.each do |part|
      return part if part.mime_type == "text/plain" && part.body&.data
      if part.parts
        found = find_text_part(part.parts)
        return found if found
      end
    end
    nil
  end

  def decode_body_data(data)
    # The Google API gem may auto-decode base64 body data.
    # If the data is already valid UTF-8 text, use it directly.
    if data.encoding == Encoding::UTF_8 || data.force_encoding(Encoding::UTF_8).valid_encoding?
      return data.force_encoding(Encoding::UTF_8)
    end

    # Otherwise try base64 decoding
    padded = data + "=" * ((4 - data.length % 4) % 4)
    decoded = Base64.urlsafe_decode64(padded)
    decoded.force_encoding(Encoding::UTF_8)
  rescue ArgumentError
    data.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
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
