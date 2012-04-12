class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :ui_state_of
  def ui_state_of(component)
    current_user.ui_states.find_or_create_by_component(component)
  end

  def current_user
    users = User.scoped
    user_id = session[:user_id]
    users = users.where :id => user_id unless user_id.nil?
    users.first!
  end

  before_filter do
    @users = User.all
    @current_user = current_user
  end
end
