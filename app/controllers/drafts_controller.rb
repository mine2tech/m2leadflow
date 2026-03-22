class DraftsController < ApplicationController
  before_action :find_draft, only: [:show, :edit, :update, :approve, :send_email, :send_later]
  before_action :require_editor!, only: [:send_email, :send_later]

  def index
    @drafts = Draft.includes(contact: :company).order(created_at: :desc)
    @drafts = @drafts.where(status: params[:status]) if params[:status].present?
  end

  def show; end

  def new
    @draft = Draft.new
    @draft.contact_id = params[:contact_id] if params[:contact_id]
    @draft.email_thread_id = params[:email_thread_id] if params[:email_thread_id]
    if @draft.email_thread_id.present?
      thread = EmailThread.find(@draft.email_thread_id)
      first_subject = thread.messages.order(:created_at).first&.subject
      @draft.subject = "Re: #{first_subject}" if first_subject.present?
    end
    @contacts = Contact.includes(:company).order(:name)
  end

  def create
    @draft = Draft.new(compose_params)
    @draft.user = current_user

    # Handle new contact creation via email address
    if @draft.contact_id.blank? && params[:email_address].present?
      contact = find_or_create_contact(params[:email_address], params[:contact_name], params[:company_id])
      @draft.contact = contact
    end

    if @draft.save
      redirect_to @draft, notice: "Draft created."
    else
      @contacts = Contact.includes(:company).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @draft.update(draft_params)
      redirect_to @draft.contact, notice: "Draft updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    @draft.update!(status: :approved)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@draft),
          partial: "drafts/draft_card",
          locals: { draft: @draft }
        )
      end
      format.html { redirect_to @draft.contact, notice: "Draft approved." }
    end
  end

  def send_email
    EmailSendingService.call(@draft)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@draft),
          partial: "drafts/draft_card",
          locals: { draft: @draft }
        )
      end
      format.html { redirect_to @draft.contact, notice: "Email sent!" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@draft),
          partial: "drafts/draft_card",
          locals: { draft: @draft }
        )
      end
      format.html { redirect_to @draft.contact, alert: "Failed to send: #{e.message}" }
    end
  end

  def send_later
    scheduled_at = Time.zone.parse(params[:scheduled_at])
    unless scheduled_at
      redirect_to @draft.contact, alert: "Invalid date/time format."
      return
    end
    @draft.update!(status: :scheduled, scheduled_at: scheduled_at)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@draft),
          partial: "drafts/draft_card",
          locals: { draft: @draft }
        )
      end
      format.html { redirect_to @draft.contact, notice: "Email scheduled for #{@draft.scheduled_at.strftime('%b %-d at %l:%M %p')}." }
    end
  rescue ArgumentError
    redirect_to @draft.contact, alert: "Invalid date/time format."
  end

  private

  def find_draft
    @draft = Draft.find(params[:id])
  end

  def draft_params
    params.require(:draft).permit(:subject, :body, attachments: [])
  end

  def compose_params
    params.require(:draft).permit(:contact_id, :subject, :body, :email_thread_id, attachments: [])
  end

  def find_or_create_contact(email, name, company_id)
    contact = Contact.find_by(email: email)
    return contact if contact

    company = Company.find(company_id) if company_id.present?
    unless company
      # Create a placeholder company from the email domain
      domain = email.split("@").last
      company = Company.find_or_create_by!(domain: domain) do |c|
        c.name = domain.split(".").first.capitalize
      end
    end

    Contact.create!(
      email: email,
      name: name.presence,
      company: company
    )
  end
end
