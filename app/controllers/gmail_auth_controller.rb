class GmailAuthController < ApplicationController
  def redirect
    client = google_client
    authorization_url = client.authorization_uri(
      scope: "https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send",
      access_type: "offline",
      prompt: "consent"
    ).to_s
    redirect_to authorization_url, allow_other_host: true
  end

  def callback
    client = google_client
    client.code = params[:code]
    response = client.fetch_access_token!

    gmail_service = Google::Apis::GmailV1::GmailService.new
    gmail_service.authorization = client
    profile = gmail_service.get_user_profile("me")

    GmailAccount.find_or_initialize_by(email: profile.email_address).tap do |account|
      account.access_token = response["access_token"]
      account.refresh_token = response["refresh_token"] if response["refresh_token"]
      account.token_expires_at = Time.current + response["expires_in"].to_i.seconds
      account.status = :active
      account.save!
    end

    redirect_to settings_path, notice: "Gmail account connected: #{profile.email_address}"
  rescue StandardError => e
    redirect_to settings_path, alert: "Gmail connection failed: #{e.message}"
  end

  private

  def google_client
    Signet::OAuth2::Client.new(
      client_id: ENV["GMAIL_CLIENT_ID"],
      client_secret: ENV["GMAIL_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: ENV["GMAIL_REDIRECT_URI"]
    )
  end
end
