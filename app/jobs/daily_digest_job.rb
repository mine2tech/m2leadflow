class DailyDigestJob < ApplicationJob
  queue_as :default

  def perform
    return unless Setting.slack_webhook_url.present?

    yesterday = 1.day.ago.all_day
    sent = Message.where(direction: :outbound, created_at: yesterday).count
    replies = Message.where(direction: :inbound, created_at: yesterday).count
    meetings = Meeting.where(created_at: yesterday).count
    drafts_reviewed = Activity.where(action: "draft_reviewed", created_at: yesterday).count
    new_contacts = Contact.where(created_at: yesterday).count

    return if sent == 0 && replies == 0 && meetings == 0 && drafts_reviewed == 0 && new_contacts == 0

    reply_rate = sent > 0 ? ((replies.to_f / sent) * 100).round(0) : 0

    classification_text = ""
    cls_counts = Message.where(direction: :inbound, created_at: yesterday)
                        .where.not(classification: nil)
                        .group(:classification).count
    if cls_counts.any?
      parts = cls_counts.map { |cls, count| "#{cls.humanize}: #{count}" }
      classification_text = "\nReply breakdown: #{parts.join(' | ')}"
    end

    SlackNotificationService.post_message(
      text: ":bar_chart: *Daily Digest* (#{1.day.ago.strftime('%b %-d, %Y')})\n" \
            "Emails sent: *#{sent}* | Replies: *#{replies}* (#{reply_rate}%) | Meetings: *#{meetings}*\n" \
            "Drafts reviewed: *#{drafts_reviewed}* | New contacts: *#{new_contacts}*" \
            "#{classification_text}"
    )
  end
end
