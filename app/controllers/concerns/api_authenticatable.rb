module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key!
  end

  private

  def authenticate_api_key!
    api_key = request.headers["X-Api-Key"]
    unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, ENV.fetch("API_KEY"))
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
