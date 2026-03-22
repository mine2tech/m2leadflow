class Activity < ApplicationRecord
  belongs_to :trackable, polymorphic: true
  belongs_to :user, optional: true

  ACTIONS = %w[
    email_sent reply_received draft_created draft_approved
    status_changed followup_created meeting_scheduled
    comment_added company_enriched contact_created task_created
    reply_reminder_sent
  ].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :recent, -> { order(created_at: :desc) }
end
