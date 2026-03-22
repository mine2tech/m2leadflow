class SlackNotificationService
  def self.reply_received(message)
    contact = message.email_thread.contact
    post_message(
      text: ":incoming_envelope: *Reply received* from #{contact.name || contact.email} (#{contact.company&.name || 'Unknown'})",
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Reply from #{contact.name || contact.email}* at #{contact.company&.name || 'Unknown'}\n>#{message.body.to_s.truncate(300)}"
          }
        }
      ]
    )
  end

  def self.comment_added(comment)
    target = comment.commentable
    label = target.respond_to?(:name) && target.name.present? ? target.name : target.try(:email) || target.class.name
    post_message(
      text: ":speech_balloon: #{comment.user.name} commented on #{target.class.name} #{label}: #{comment.body.truncate(200)}"
    )
  end

  def self.reply_reminder(contact)
    post_message(
      text: ":alarm_clock: *Reply needs response* - #{contact.name || contact.email} (#{contact.company&.name || 'Unknown'}) replied but no response has been sent yet."
    )
  end

  def self.post_message(payload)
    webhook_url = Setting.slack_webhook_url
    return unless webhook_url.present?

    uri = URI(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    request.body = payload.to_json
    http.request(request)
  rescue StandardError => e
    Rails.logger.error("Slack notification failed: #{e.message}")
  end
end
