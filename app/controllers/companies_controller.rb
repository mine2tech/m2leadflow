class CompaniesController < ApplicationController
  before_action :find_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.includes(:contacts).order(created_at: :desc)
    @companies = @companies.where(status: params[:status]) if params[:status].present?

    # Pre-compute stats via SQL to avoid N+1
    company_ids = @companies.pluck(:id)
    @enriched_count = @companies.where(status: [:enriched, :completed]).count
    @with_replies = Company.where(id: company_ids)
                           .joins(contacts: { email_threads: :messages })
                           .where(messages: { direction: :inbound })
                           .distinct.count
    @with_meetings = Company.where(id: company_ids)
                            .joins(contacts: :meetings)
                            .where.not(meetings: { id: nil })
                            .distinct.count
  end

  def show
    @contacts = @company.contacts
                  .includes(:drafts, :meetings, email_threads: :messages)
                  .order(created_at: :desc)
    @contacts = @contacts.select { |c| c.pipeline_stage.to_s == params[:stage] } if params[:stage].present?

    contact_ids = @company.contact_ids
    @activities = Activity.where(trackable: @company)
                          .or(Activity.where(trackable_type: "Contact", trackable_id: contact_ids))
                          .includes(:user)
                          .order(created_at: :desc)
                          .limit(50)
    @comments = @company.comments.includes(:user).order(created_at: :asc)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      ActivityTracker.track(@company, action: "company_created", user: current_user, metadata: {
        name: @company.name, domain: @company.domain
      })
      redirect_to @company, notice: "Company created. Enrichment task queued."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Company updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "Company deleted."
  end

  private

  def find_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :domain, :notes, :status, :industry, :employee_count,
      :revenue_range, :funding_info, :tech_stack, :recent_breaches, :security_posture,
      :headquarters, :website_description)
  end
end
