class FollowupsController < ApplicationController
  def index
    @followups = Followup.includes(contact: :company).order(scheduled_at: :asc)
    @followups = @followups.where(status: params[:status]) if params[:status].present?

    all_followups = Followup.all
    @pending_count = all_followups.where(status: :pending).count
    @overdue_count = all_followups.where(status: :pending).where("scheduled_at < ?", 7.days.ago).count
    @completed_count = all_followups.where(status: :completed).count
    @total_count = all_followups.count
  end

  def skip
    followup = Followup.find(params[:id])
    followup.update!(status: :skipped)
    ActivityTracker.track(followup.contact, action: "followup_skipped", user: current_user, metadata: {
      followup_id: followup.id, sequence_number: followup.sequence_number
    })
    redirect_to followup.contact, notice: "Followup skipped."
  end
end
