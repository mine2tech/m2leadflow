class CalendarAccount < ApplicationRecord
  encrypts :access_token_ciphertext
  encrypts :refresh_token_ciphertext

  alias_attribute :access_token, :access_token_ciphertext
  alias_attribute :refresh_token, :refresh_token_ciphertext

  enum :status, { active: 0, expired: 1, revoked: 2 }

  validates :email, presence: true, uniqueness: true

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end
end
