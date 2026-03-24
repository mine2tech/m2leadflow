class SettingsController < ApplicationController
  before_action :require_admin!

  def index
    @gmail_accounts = GmailAccount.all
    @calendar_account = CalendarAccount.active.first
    @apollo_accounts = ApolloAccount.all
    @followup_delay_days = Setting.followup_delay_days
    @max_followups = Setting.max_followups
    @auto_send_followups = Setting.auto_send_followups?
    @followup_use_ai = Setting.followup_use_ai?
    @slack_webhook_url = Setting.slack_webhook_url
    @reply_reminder_hours = Setting.reply_reminder_hours
  end

  def update_followup_defaults
    Setting.set("followup_delay_days", params[:followup_delay_days])
    Setting.set("max_followups", params[:max_followups])
    Setting.set("auto_send_followups", params[:auto_send_followups] == "1" ? "true" : "false")
    Setting.set("followup_use_ai", params[:followup_use_ai] == "1" ? "true" : "false")
    redirect_to settings_path, notice: "Followup settings updated."
  end

  def update_slack_settings
    Setting.set("slack_webhook_url", params[:slack_webhook_url])
    Setting.set("reply_reminder_hours", params[:reply_reminder_hours])
    redirect_to settings_path, notice: "Slack settings updated."
  end
end
