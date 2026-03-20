module TaskResultProcessors
  class EnrichCompany
    def self.call(task)
      contacts = task.result["contacts"] || []
      company = Company.find(task.payload["company_id"])

      contacts.each do |contact_data|
        Contact.find_or_create_by(email: contact_data["email"]) do |c|
          c.company = company
          c.name = contact_data["name"]
          c.role = contact_data["role"]
          c.source = contact_data["source"] || "apollo"
          c.confidence_score = contact_data["confidence_score"]
        end
      end

      company.update!(status: :enriched)
    end
  end
end
