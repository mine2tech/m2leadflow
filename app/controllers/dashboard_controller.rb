class DashboardController < ApplicationController
  def index
    @companies_count = Company.count
    @contacts_count = Contact.count
    @drafts_pending = Draft.where(status: :draft).count
    @emails_sent = Message.where(direction: :outbound).count
    @replies_count = Message.where(direction: :inbound).count
    @meetings_count = Meeting.count
    @reply_rate = @emails_sent > 0 ? ((@replies_count.to_f / @emails_sent) * 100).round(1) : 0

    # Pipeline stage counts
    contacts = Contact.includes(:drafts, :meetings, email_threads: :messages).all
    @pipeline_stages = { pending: 0, drafted: 0, sent: 0, replied: 0, meeting: 0 }
    contacts.each { |c| @pipeline_stages[c.pipeline_stage] = (@pipeline_stages[c.pipeline_stage] || 0) + 1 }

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
