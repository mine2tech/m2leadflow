class Draft < ApplicationRecord
  belongs_to :contact
  belongs_to :email_thread, optional: true
  belongs_to :user, optional: true
  has_one :followup, dependent: :nullify
  has_many_attached :attachments

  enum :status, { draft: 0, approved: 1, sent: 2, scheduled: 3 }

  validates :subject, presence: true
  validates :body, presence: true

  scope :needs_sending, -> { where(status: :scheduled).where("scheduled_at <= ?", Time.current) }
end
