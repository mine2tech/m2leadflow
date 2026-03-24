class FollowupCheckJob < ApplicationJob
  queue_as :default

  def perform
    FollowupService.check_and_create
  end
end
