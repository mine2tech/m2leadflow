class CompaniesController < ApplicationController
  before_action :find_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.includes(:contacts).order(created_at: :desc)
    @companies = @companies.where(status: params[:status]) if params[:status].present?
  end

  def show
    @contacts = @company.contacts
                  .includes(:drafts, :meetings, email_threads: :messages)
                  .order(created_at: :desc)
    @contacts = @contacts.select { |c| c.pipeline_stage.to_s == params[:stage] } if params[:stage].present?

    @activities = @company.activities.includes(:user).order(created_at: :desc).limit(50)
    @comments = @company.comments.includes(:user).order(created_at: :asc)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
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
