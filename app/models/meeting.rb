class Meeting < ApplicationRecord
  belongs_to :contact

  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  validates :scheduled_at, presence: true
end
