class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include VersionChecker
  before_action :authenticate_user!, unless: :auth_routes?

  skip_before_action :verify_authenticity_token

  private

  def auth_routes?
    request.path.start_with?("/auth")
  end
end
