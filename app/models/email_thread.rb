class EmailThread < ApplicationRecord
  belongs_to :contact
  has_many :messages, dependent: :destroy
  has_many :drafts

  def has_inbound?
    messages.where(direction: :inbound).exists?
  end
end
