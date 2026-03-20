class ApplicationController < ActionController::Base
  include BasicAuthenticatable

  allow_browser versions: :modern
  stale_when_importmap_changes
end
