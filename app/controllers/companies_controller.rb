class CompaniesController < ApplicationController
  before_action :find_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.order(created_at: :desc)
  end

  def show
    @contacts = @company.contacts
                  .includes(:drafts, :meetings, email_threads: :messages)
                  .order(created_at: :desc)
    @contacts = @contacts.select { |c| c.pipeline_stage.to_s == params[:stage] } if params[:stage].present?
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
    params.require(:company).permit(:name, :domain, :notes, :status)
  end
end
