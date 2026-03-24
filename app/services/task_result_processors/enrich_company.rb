module TaskResultProcessors
  class EnrichCompany
    COMPANY_FIELDS = %w[
      industry employee_count revenue_range funding_info tech_stack
      recent_breaches security_posture headquarters website_description
    ].freeze

    def self.call(task)
      contacts = task.result["contacts"] || []
      company = Company.find(task.payload["company_id"])

      contacts.each do |contact_data|
        next if contact_data["email"].blank?
        Contact.find_or_create_by(email: contact_data["email"]) do |c|
          c.company = company
          c.name = contact_data["name"]
          c.role = contact_data["role"]
          c.source = contact_data["source"] || "apollo"
          c.confidence_score = contact_data["confidence_score"]
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("EnrichCompany: Failed to create contact #{contact_data['email']}: #{e.message}")
      end

      # Store enrichment data if provided
      if (company_data = task.result["company_data"])
        attrs = {}
        COMPANY_FIELDS.each do |field|
          attrs[field] = company_data[field] if company_data.key?(field)
        end
        # Store any extra fields in enrichment_data JSONB
        extra = company_data.except(*COMPANY_FIELDS)
        attrs[:enrichment_data] = (company.enrichment_data || {}).merge(extra) if extra.any?
        company.assign_attributes(attrs)
      end

      company.update!(status: :enriched)
    end
  end
end
