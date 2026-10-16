class SessionsController < ApplicationController
  skip_before_action :require_login!, only: %i[new create]

  def new
    render inertia: "Auth/Login"
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.authenticate(params[:password]) && user.active?
      reset_session
      session[:user_id] = user.id
      redirect_to root_path
    else
      render inertia: "Auth/Login", props: { error: "Email or password is incorrect" }, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path
  end
end
