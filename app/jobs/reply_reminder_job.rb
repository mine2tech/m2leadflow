class ReplyReminderJob < ApplicationJob
  queue_as :default

  def perform
    reminder_hours = Setting.reply_reminder_hours
    return if reminder_hours <= 0
    return unless Setting.slack_webhook_url.present?

    cutoff = reminder_hours.hours.ago

    Contact.joins(email_threads: :messages).where(messages: { direction: :inbound }).distinct.find_each do |contact|
      last_inbound = contact.email_threads.joins(:messages)
                            .where(messages: { direction: :inbound })
                            .maximum("messages.created_at")
      next unless last_inbound
      next if last_inbound > cutoff # Reply is still recent

      # Check if we responded after the reply
      last_outbound_after_reply = contact.email_threads.joins(:messages)
                                        .where(messages: { direction: :outbound })
                                        .where("messages.created_at > ?", last_inbound)
                                        .exists?
      next if last_outbound_after_reply

      # Check if we already sent a reminder for this reply
      already_reminded = Activity.where(
        trackable: contact,
        action: "reply_reminder_sent"
      ).where("created_at > ?", last_inbound).exists?
      next if already_reminded

      SlackNotificationService.reply_reminder(contact)
      ActivityTracker.track(contact, action: "reply_reminder_sent")
    end
  end
end
