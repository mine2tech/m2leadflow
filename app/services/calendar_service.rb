class CalendarService
  def self.create_event(meeting)
    new.create_event(meeting)
  end

  def self.update_event(meeting)
    new.update_event(meeting)
  end

  def self.cancel_event(meeting)
    new.cancel_event(meeting)
  end

  def initialize
    @account = CalendarAccount.active.first
    raise "No active Calendar account configured. Add one in Settings." unless @account
  end

  def create_event(meeting)
    refresh_token_if_needed!

    event = build_event(meeting)
    event.conference_data = Google::Apis::CalendarV3::ConferenceData.new(
      create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
        request_id: SecureRandom.uuid,
        conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(type: "hangoutsMeet")
      )
    )

    result = @service.insert_event(
      "primary",
      event,
      conference_data_version: 1,
      send_updates: "all"
    )

    meeting.update!(
      calendar_event_id: result.id,
      meeting_link: result.hangout_link
    )

    result
  end

  def update_event(meeting)
    return unless meeting.calendar_event_id

    refresh_token_if_needed!

    event = build_event(meeting)
    @service.update_event("primary", meeting.calendar_event_id, event, send_updates: "all")
  end

  def cancel_event(meeting)
    return unless meeting.calendar_event_id

    refresh_token_if_needed!
    @service.delete_event("primary", meeting.calendar_event_id, send_updates: "all")
  end

  private

  def build_event(meeting)
    Google::Apis::CalendarV3::Event.new(
      summary: "Meeting with #{meeting.contact.name || meeting.contact.email}",
      description: meeting.agenda,
      location: meeting.location,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: meeting.scheduled_at.iso8601,
        time_zone: Time.zone.name
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: meeting.end_time.iso8601,
        time_zone: Time.zone.name
      ),
      attendees: meeting.all_invitees.map { |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email)
      }
    )
  end

  def refresh_token_if_needed!
    @service = Google::Apis::CalendarV3::CalendarService.new
    client = Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @account.access_token,
      refresh_token: @account.refresh_token,
      expires_at: @account.token_expires_at
    )

    if @account.token_expired?
      client.fetch_access_token!
      @account.update!(
        access_token: client.access_token,
        token_expires_at: Time.current + client.expires_in.to_i.seconds,
        status: :active
      )
    end

    @service.authorization = client
  end
end
