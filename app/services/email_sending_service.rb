class EmailSendingService
  def self.call(draft, sent_by: nil)
    GmailSendingService.call(draft, sent_by: sent_by)
  end
end
