class Message < ApplicationRecord
  belongs_to :email_thread
  has_many_attached :attachments

  enum :direction, { outbound: 0, inbound: 1 }

  validates :direction, presence: true
  validates :body, presence: true
end
