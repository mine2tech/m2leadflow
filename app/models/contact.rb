class Contact < ApplicationRecord
  belongs_to :company
  has_many :email_threads, dependent: :destroy
  has_many :messages, through: :email_threads
  has_many :drafts, dependent: :destroy
  has_many :followups, dependent: :destroy
  has_many :meetings, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_draft_email_task

  def pipeline_stage
    return :meeting if meetings.where(status: :scheduled).exists?
    return :replied  if has_reply?
    return :sent     if messages.where(direction: :outbound).exists?
    return :drafted  if drafts.exists?
    :pending
  end

  def has_reply?
    email_threads.joins(:messages).where(messages: { direction: :inbound }).exists?
  end

  def last_outbound_at
    email_threads.joins(:messages)
      .where(messages: { direction: :outbound })
      .maximum("messages.created_at")
  end

  def followup_count
    followups.where(status: :completed).count
  end

  private

  def create_draft_email_task
    Task.create!(
      task_type: "draft_email",
      payload: {
        contact_id: id,
        company_context: company.slice(:name, :domain, :notes),
        contact: { name: name, role: role },
        is_followup: false,
        sequence_number: 1
      }
    )
  end
end
