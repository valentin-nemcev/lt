module UsersHelper
  def user_selector
    users = User.all
    content_tag :div, :id => 'user_selector' do
      form_tag select_user_path do
        user_id = current_user.id
        opts = options_from_collection_for_select users, :id, :name, user_id
        select_tag :user_id, opts
      end
    end
  end

  def current_user
    users = User.scoped
    user_id = session[:user_id]
    users = users.where :id => user_id unless user_id.nil?
    users.first!
  end
end
