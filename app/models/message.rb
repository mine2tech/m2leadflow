class Message < ApplicationRecord
  belongs_to :email_thread
  has_many_attached :attachments

  enum :direction, { outbound: 0, inbound: 1 }
  enum :classification, {
    interested: 0,
    not_interested: 1,
    out_of_office: 2,
    wrong_person: 3,
    auto_reply: 4
  }, prefix: true

  validates :direction, presence: true
  validates :body, presence: true
end
