class DashboardController < ApplicationController
  def index
    @companies_count = Company.count
    @contacts_count = Contact.count
    @drafts_pending = Draft.where(status: :draft).count
    @emails_sent = Message.where(direction: :outbound).count
    @replies_count = Message.where(direction: :inbound).count
    @meetings_count = Meeting.count
    @reply_rate = @emails_sent > 0 ? ((@replies_count.to_f / @emails_sent) * 100).round(1) : 0

    # Pipeline stage counts (SQL-based to avoid loading all contacts)
    meeting_ids = Contact.joins(:meetings).where(meetings: { status: :scheduled }).distinct.pluck(:id)
    replied_ids = Contact.joins(email_threads: :messages).where(messages: { direction: :inbound }).where.not(id: meeting_ids).distinct.pluck(:id)
    sent_ids = Contact.joins(email_threads: :messages).where(messages: { direction: :outbound }).where.not(id: meeting_ids + replied_ids).distinct.pluck(:id)
    drafted_ids = Contact.joins(:drafts).where.not(id: meeting_ids + replied_ids + sent_ids).distinct.pluck(:id)
    @pipeline_stages = {
      meeting: meeting_ids.size,
      replied: replied_ids.size,
      sent: sent_ids.size,
      drafted: drafted_ids.size,
      pending: @contacts_count - meeting_ids.size - replied_ids.size - sent_ids.size - drafted_ids.size
    }

    @recent_replies = Message.where(direction: :inbound)
                             .includes(email_thread: { contact: :company })
                             .order(created_at: :desc)
                             .limit(5)

    @drafts_to_review = Draft.where(status: :draft)
                             .includes(contact: :company)
                             .order(created_at: :desc)
                             .limit(5)
  end
end
