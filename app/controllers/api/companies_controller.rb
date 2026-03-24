module Api
  class CompaniesController < BaseController
    # POST /api/companies
    def create
      company = Company.new(company_params)
      if company.save
        render json: {
          id: company.id,
          name: company.name,
          domain: company.domain,
          status: company.status,
          notes: company.notes
        }, status: :created
      else
        render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /api/companies/bulk
    def bulk_create
      companies = params[:companies] || []
      created = []
      skipped = []

      companies.each do |company_data|
        if Company.exists?(domain: company_data[:domain])
          skipped << { domain: company_data[:domain], reason: "already exists" }
        else
          company = Company.new(company_data.permit(:name, :domain, :notes, :industry, :employee_count,
            :revenue_range, :funding_info, :tech_stack, :recent_breaches, :security_posture,
            :headquarters, :website_description))
          if company.save
            created << { id: company.id, name: company.name, domain: company.domain }
          else
            skipped << { domain: company_data[:domain], reason: company.errors.full_messages.join(", ") }
          end
        end
      end

      render json: { created: created.size, skipped: skipped, companies: created }
    end

    private

    def company_params
      params.require(:company).permit(:name, :domain, :notes, :industry, :employee_count,
        :revenue_range, :funding_info, :tech_stack, :recent_breaches, :security_posture,
        :headquarters, :website_description)
    end
  end
end
