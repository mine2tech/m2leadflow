class ScheduledEmailSendJob < ApplicationJob
  queue_as :default

  def perform
    Draft.needs_sending.find_each do |draft|
      EmailSendingService.call(draft)
    rescue StandardError => e
      Rails.logger.error("Failed to send scheduled draft #{draft.id}: #{e.message}")
    end
  end
end
