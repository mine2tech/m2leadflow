class MeetingsController < ApplicationController
  before_action :find_meeting, only: [:edit, :update, :destroy]

  def index
    meetings = Meeting.includes(contact: :company).order(scheduled_at: :desc)
    @upcoming_meetings = meetings.select { |m| m.scheduled_at && m.scheduled_at >= Time.current && m.scheduled? }
    @past_meetings = meetings - @upcoming_meetings
  end

  def new
    @meeting = Meeting.new(contact_id: params[:contact_id])
    if @meeting.contact_id && (contact = Contact.find_by(id: @meeting.contact_id))
      @meeting.invitees = [contact.email]
    end
    @contacts = Contact.includes(:company).order(:name)
    @calendar_connected = CalendarAccount.active.exists?
  end

  def create
    @meeting = Meeting.new(meeting_params)
    if @meeting.save
      ActivityTracker.track(@meeting.contact, action: "meeting_scheduled", user: current_user, metadata: {
        meeting_id: @meeting.id, scheduled_at: @meeting.scheduled_at&.iso8601
      })
      sync_to_calendar if params[:create_calendar_event] == "1"
      redirect_to meetings_path, notice: flash_notice_for_create
    else
      @contacts = Contact.includes(:company).order(:name)
      @calendar_connected = CalendarAccount.active.exists?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @contacts = Contact.includes(:company).order(:name)
    @calendar_connected = CalendarAccount.active.exists?
  end

  def update
    if @meeting.update(meeting_params)
      sync_calendar_update if @meeting.synced_to_calendar?
      redirect_to meetings_path, notice: flash_notice_for_update
    else
      @contacts = Contact.includes(:company).order(:name)
      @calendar_connected = CalendarAccount.active.exists?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cancel_calendar_event if @meeting.synced_to_calendar?
    @meeting.destroy
    redirect_to meetings_path, notice: "Meeting removed."
  end

  private

  def find_meeting
    @meeting = Meeting.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(
      :contact_id, :scheduled_at, :meeting_link, :notes, :status,
      :duration_minutes, :agenda, :location, invitees: []
    )
  end

  def sync_to_calendar
    CalendarService.create_event(@meeting)
    ActivityTracker.track(@meeting.contact, action: "meeting_calendar_synced", metadata: {
      meeting_id: @meeting.id, calendar_event_id: @meeting.calendar_event_id
    })
  rescue StandardError => e
    Rails.logger.error("Calendar event creation failed: #{e.message}")
    flash[:alert] = "Meeting saved, but Google Calendar sync failed: #{e.message}"
  end

  def sync_calendar_update
    CalendarService.update_event(@meeting)
  rescue StandardError => e
    Rails.logger.error("Calendar event update failed: #{e.message}")
    flash[:alert] = "Meeting updated, but Google Calendar sync failed: #{e.message}"
  end

  def cancel_calendar_event
    CalendarService.cancel_event(@meeting)
  rescue StandardError => e
    Rails.logger.error("Calendar event cancellation failed: #{e.message}")
  end

  def flash_notice_for_create
    if @meeting.synced_to_calendar?
      "Meeting scheduled and added to Google Calendar."
    else
      "Meeting scheduled."
    end
  end

  def flash_notice_for_update
    if @meeting.synced_to_calendar?
      "Meeting updated. Google Calendar event synced."
    else
      "Meeting updated."
    end
  end
end
