class ApolloAccount < ApplicationRecord
  encrypts :credentials_encrypted

  enum :status, { active: 0, exhausted: 1 }

  validates :email, presence: true, uniqueness: true

  scope :available, -> { active.order(credits_remaining: :desc) }
end
