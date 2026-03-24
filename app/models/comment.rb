class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  validates :body, presence: true

  after_create :create_activity
  after_create :notify_slack

  private

  def create_activity
    Activity.create!(
      trackable: commentable,
      user: user,
      action: "comment_added",
      metadata: { body: body.truncate(200) }
    )
  end

  def notify_slack
    SlackNotificationService.comment_added(self) if Setting.slack_webhook_url.present?
  end
end
