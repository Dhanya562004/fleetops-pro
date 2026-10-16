class ApplicationController < ActionController::Base
  inertia_share do
    {
      currentUser: current_user&.as_json(only: %i[id name email role]),
      flash: flash.to_hash
    }
  end

  before_action :require_login!

  helper_method :current_user

  private

  def current_user
    return nil if session[:user_id].blank?

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login!
    redirect_to new_session_path, alert: "Please sign in to continue" unless current_user
  end

  def require_role!(*roles)
    head :forbidden unless current_user&.role.in?(roles.map(&:to_s))
  end
end
