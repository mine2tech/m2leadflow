class GmailPollJob < ApplicationJob
  queue_as :default

  def perform
    GmailPollingService.call
  end
end
