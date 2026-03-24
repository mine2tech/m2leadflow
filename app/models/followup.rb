class Followup < ApplicationRecord
  belongs_to :contact
  belongs_to :draft, optional: true

  enum :status, { pending: 0, completed: 1, skipped: 2 }

  validates :delay_days, presence: true
  validates :sequence_number, presence: true
end
