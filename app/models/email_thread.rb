class EmailThread < ApplicationRecord
  belongs_to :contact
  has_many :messages, dependent: :destroy
  has_many :drafts, dependent: :nullify

  def has_inbound?
    messages.where(direction: :inbound).exists?
  end
end
