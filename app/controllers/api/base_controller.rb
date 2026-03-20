module Api
  class BaseController < ActionController::API
    include ApiAuthenticatable
  end
end
