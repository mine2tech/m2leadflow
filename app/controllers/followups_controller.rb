class FollowupsController < ApplicationController
  def index
    @followups = Followup.includes(contact: :company).order(scheduled_at: :asc)
    @followups = @followups.where(status: params[:status]) if params[:status].present?

    all_followups = Followup.all
    @pending_count = all_followups.where(status: :pending).count
    @overdue_count = all_followups.where(status: :pending).where("scheduled_at < ?", 7.days.ago).count
    @completed_count = all_followups.where(status: :completed).count
  end

  def skip
    followup = Followup.find(params[:id])
    followup.update!(status: :skipped)
    redirect_to followup.contact, notice: "Followup skipped."
  end
end
