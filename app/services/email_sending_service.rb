class EmailSendingService
  def self.call(draft)
    GmailSendingService.call(draft)
  end
end
