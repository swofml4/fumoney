class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  def check_admin_access
  	authenticate_user!
  	if current_user.admin_flag
		return
	else
		redirect_to root_url , notice: 'Sorry, only admins can access that'
	end
  end
end
