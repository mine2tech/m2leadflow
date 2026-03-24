class DraftsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :find_draft, only: [:show, :edit, :update, :approve, :unapprove, :send_email, :send_later]
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

  def edit
    redirect_to @draft.contact, alert: "Cannot edit a #{@draft.status} draft." if @draft.sent?
  end

  def update
    if @draft.sent?
      redirect_to @draft.contact, alert: "Cannot edit a sent draft."
      return
    end
    if @draft.update(draft_params)
      ActivityTracker.track(@draft.contact, action: "draft_edited", user: current_user, metadata: {
        draft_id: @draft.id, subject: @draft.subject
      })
      redirect_to @draft.contact, notice: "Draft updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    unless @draft.draft?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
            turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft })
          ]
        end
        format.html { redirect_to @draft.contact }
      end
      return
    end

    @draft.update!(status: :reviewed)
    ActivityTracker.track(@draft.contact, action: "draft_reviewed", user: current_user, metadata: {
      draft_id: @draft.id, subject: @draft.subject
    })
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
          turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
          turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Draft marked as reviewed", variant: :success })
        ]
      end
      format.html { redirect_to @draft.contact, notice: "Draft reviewed." }
    end
  end

  def unapprove
    unless @draft.reviewed?
      redirect_to @draft.contact and return
    end

    @draft.update!(status: :draft)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
          turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
          turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Reverted to draft", variant: :success })
        ]
      end
      format.html { redirect_to @draft.contact, notice: "Reverted to draft." }
    end
  end

  def send_email
    unless @draft.reviewed?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
            turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
            turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Draft is not ready to send (status: #{@draft.status})", variant: :error })
          ]
        end
        format.html { redirect_to @draft.contact, alert: "Draft is not ready to send." }
      end
      return
    end

    EmailSendingService.call(@draft, sent_by: current_user)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
          turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
          turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Email sent!", variant: :success })
        ]
      end
      format.html { redirect_to @draft.contact, notice: "Email sent!" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
          turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
          turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Failed to send: #{e.message}", variant: :error })
        ]
      end
      format.html { redirect_to @draft.contact, alert: "Failed to send: #{e.message}" }
    end
  end

  def send_later
    unless @draft.draft? || @draft.reviewed?
      redirect_to @draft.contact, alert: "Cannot schedule a draft that is already #{@draft.status}."
      return
    end
    scheduled_at = Time.zone.parse(params[:scheduled_at])
    unless scheduled_at
      redirect_to @draft.contact, alert: "Invalid date/time format."
      return
    end
    @draft.update!(status: :scheduled, scheduled_at: scheduled_at)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(dom_id(@draft), partial: "drafts/draft_card", locals: { draft: @draft }),
          turbo_stream.replace(dom_id(@draft, :row), partial: "drafts/draft_row", locals: { draft: @draft }),
          turbo_stream.append("flash-messages", partial: "shared/flash_toast", locals: { message: "Email scheduled for #{@draft.scheduled_at.strftime('%b %-d at %l:%M %p')}.", variant: :success })
        ]
      end
      format.html { redirect_to @draft.contact, notice: "Email scheduled for #{@draft.scheduled_at.strftime('%b %-d at %l:%M %p')}." }
    end
  rescue ArgumentError
    redirect_to @draft.contact, alert: "Invalid date/time format."
  end

  def bulk_approve
    ids = params[:draft_ids].to_s.split(",").map(&:to_i).reject(&:zero?)
    drafts = Draft.where(id: ids, status: :draft).includes(:contact)
    count = drafts.size

    drafts.each do |draft|
      draft.update!(status: :reviewed)
      ActivityTracker.track(draft.contact, action: "draft_reviewed", user: current_user, metadata: {
        draft_id: draft.id, subject: draft.subject
      })
    end

    respond_to do |format|
      format.turbo_stream do
        streams = drafts.map { |draft|
          turbo_stream.replace(dom_id(draft, :row), partial: "drafts/draft_row", locals: { draft: draft })
        }
        streams << turbo_stream.append("flash-messages", partial: "shared/flash_toast",
          locals: { message: "#{count} drafts reviewed", variant: :success })
        render turbo_stream: streams
      end
      format.html { redirect_to drafts_path(status: :draft), notice: "#{count} drafts reviewed." }
    end
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
