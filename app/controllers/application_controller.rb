class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def require_editor!
    unless current_user.can_send_email?
      redirect_to root_path, alert: "You don't have permission to perform this action."
    end
  end

  def require_admin!
    unless current_user.admin?
      redirect_to root_path, alert: "Admin access required."
    end
  end
end
