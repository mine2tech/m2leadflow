class SettingsController < ApplicationController
  def index
    @gmail_accounts = GmailAccount.all
    @apollo_accounts = ApolloAccount.all
    @followup_delay_days = Setting.followup_delay_days
    @max_followups = Setting.max_followups
    @auto_send_followups = Setting.auto_send_followups?
    @followup_use_ai = Setting.followup_use_ai?
  end

  def update_followup_defaults
    Setting.set("followup_delay_days", params[:followup_delay_days])
    Setting.set("max_followups", params[:max_followups])
    Setting.set("auto_send_followups", params[:auto_send_followups] || "false")
    Setting.set("followup_use_ai", params[:followup_use_ai] || "true")
    redirect_to settings_path, notice: "Followup settings updated."
  end
end
