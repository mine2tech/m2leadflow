module TaskResultProcessors
  class CompanyResearch
    COMPANY_FIELDS = %w[
      industry employee_count revenue_range funding_info tech_stack
      recent_breaches security_posture headquarters website_description
    ].freeze

    def self.call(task)
      companies = task.result&.dig("companies") || []

      companies.each do |company_data|
        domain = company_data["domain"]&.downcase&.strip
        next if domain.blank?

        attrs = {
          name: company_data["name"],
          domain: domain,
          notes: company_data["notes"]
        }

        # Map enrichment fields directly
        COMPANY_FIELDS.each do |field|
          attrs[field] = company_data[field] if company_data.key?(field)
        end

        # Extra fields go into enrichment_data JSONB
        known_keys = COMPANY_FIELDS + %w[name domain notes]
        extra = company_data.except(*known_keys)
        attrs[:enrichment_data] = extra if extra.any?

        # find_or_create_by to handle race conditions on domain uniqueness
        # Creating a new company triggers after_create :create_enrich_task
        Company.find_or_create_by!(domain: domain) do |c|
          attrs.except(:domain).each { |k, v| c.send(:"#{k}=", v) }
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("CompanyResearch: Failed to create company #{domain}: #{e.message}")
      end
    end
  end
end
