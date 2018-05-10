class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def handle_unverified_request
    render json: {error: "Invalid authenticity token or cookie."}
    logger.fatal "'Invalid authenticity token or cookie #{request.params} #{request.headers['cookie']}'"
  end

end
