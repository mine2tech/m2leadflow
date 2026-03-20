class FollowupsController < ApplicationController
  def index
    @followups = Followup.includes(contact: :company).order(scheduled_at: :asc)
    @followups = @followups.where(status: params[:status]) if params[:status].present?
  end

  def skip
    followup = Followup.find(params[:id])
    followup.update!(status: :skipped)
    redirect_to followup.contact, notice: "Followup skipped."
  end
end
