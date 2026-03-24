class AddEnrichmentFieldsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :industry, :string
    add_column :companies, :employee_count, :integer
    add_column :companies, :revenue_range, :string
    add_column :companies, :funding_info, :string
    add_column :companies, :tech_stack, :text
    add_column :companies, :recent_breaches, :text
    add_column :companies, :security_posture, :text
    add_column :companies, :headquarters, :string
    add_column :companies, :website_description, :text
    add_column :companies, :enrichment_data, :jsonb, default: {}
  end
end
