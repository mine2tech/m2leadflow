class MeetingsController < ApplicationController
  before_action :find_meeting, only: [:edit, :update, :destroy]

  def index
    @meetings = Meeting.includes(contact: :company).order(scheduled_at: :desc)
  end

  def new
    @meeting = Meeting.new
    @contacts = Contact.includes(:company).order(:name)
  end

  def create
    @meeting = Meeting.new(meeting_params)
    if @meeting.save
      redirect_to meetings_path, notice: "Meeting scheduled."
    else
      @contacts = Contact.includes(:company).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @contacts = Contact.includes(:company).order(:name)
  end

  def update
    if @meeting.update(meeting_params)
      redirect_to meetings_path, notice: "Meeting updated."
    else
      @contacts = Contact.includes(:company).order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @meeting.destroy
    redirect_to meetings_path, notice: "Meeting removed."
  end

  private

  def find_meeting
    @meeting = Meeting.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(:contact_id, :scheduled_at, :meeting_link, :notes, :status)
  end
end
