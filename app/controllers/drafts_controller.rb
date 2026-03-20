class DraftsController < ApplicationController
  before_action :find_draft, only: [:show, :edit, :update, :approve, :send_email]

  def index
    @drafts = Draft.includes(contact: :company).order(created_at: :desc)
    @drafts = @drafts.where(status: params[:status]) if params[:status].present?
  end

  def show; end

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
  rescue => e
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

  private

  def find_draft
    @draft = Draft.find(params[:id])
  end

  def draft_params
    params.require(:draft).permit(:subject, :body)
  end
end
