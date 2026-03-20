module BasicAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    authenticate_or_request_with_http_basic("M2Leadflow") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("BASIC_AUTH_USERNAME")) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("BASIC_AUTH_PASSWORD"))
    end
  end
end
