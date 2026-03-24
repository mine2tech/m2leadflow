class Meeting < ApplicationRecord
  belongs_to :contact

  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  validates :scheduled_at, presence: true
  validates :duration_minutes, numericality: { greater_than: 0 }, allow_nil: true

  def end_time
    scheduled_at + (duration_minutes || 30).minutes if scheduled_at
  end

  def synced_to_calendar?
    calendar_event_id.present?
  end

  def all_invitees
    invitees.presence || [contact.email].compact
  end
end
