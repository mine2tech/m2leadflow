class CalendarAuthController < ApplicationController
  def redirect
    client = google_client
    authorization_url = client.authorization_uri(
      scope: "https://www.googleapis.com/auth/calendar",
      access_type: "offline",
      prompt: "consent"
    ).to_s
    redirect_to authorization_url, allow_other_host: true
  end

  def callback
    client = google_client
    client.code = params[:code]
    response = client.fetch_access_token!

    calendar_service = Google::Apis::CalendarV3::CalendarService.new
    calendar_service.authorization = client
    calendar = calendar_service.get_calendar("primary")

    CalendarAccount.find_or_initialize_by(email: calendar.id).tap do |account|
      account.access_token = response["access_token"]
      account.refresh_token = response["refresh_token"] if response["refresh_token"]
      account.token_expires_at = Time.current + response["expires_in"].to_i.seconds
      account.status = :active
      account.save!
    end

    redirect_to settings_path, notice: "Calendar account connected: #{calendar.id}"
  rescue StandardError => e
    redirect_to settings_path, alert: "Calendar connection failed: #{e.message}"
  end

  private

  def google_client
    Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: ENV.fetch("GOOGLE_CALENDAR_REDIRECT_URI", "http://localhost:3001/auth/calendar/callback")
    )
  end
end
