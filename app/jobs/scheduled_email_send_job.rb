class ScheduledEmailSendJob < ApplicationJob
  queue_as :default

  def perform
    Draft.needs_sending.find_each do |draft|
      draft.with_lock do
        next unless draft.scheduled?

        EmailSendingService.call(draft, sent_by: draft.user)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to send scheduled draft #{draft.id}: #{e.message}")
    end
  end
end
