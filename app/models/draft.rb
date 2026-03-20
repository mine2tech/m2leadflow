class Draft < ApplicationRecord
  belongs_to :contact
  belongs_to :email_thread, optional: true
  has_one :followup

  enum :status, { draft: 0, approved: 1, sent: 2 }

  validates :subject, presence: true
  validates :body, presence: true
end
