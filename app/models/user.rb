class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  enum :role, { editor: 1, admin: 2 }

  has_many :comments, dependent: :destroy
  has_many :activities, dependent: :nullify
  has_many :drafts, dependent: :nullify
  has_many :tasks, dependent: :nullify

  validates :name, presence: true

  def can_send_email?
    editor? || admin?
  end

  def can_manage_settings?
    admin?
  end

  def can_manage_users?
    admin?
  end
end
