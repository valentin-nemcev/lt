module UsersHelper
  def user_selector
    users = User.all
    content_tag :div, :id => 'user_selector' do
      form_tag select_user_path do
        opts = options_from_collection_for_select users, :id, :name
        select_tag 'user', opts
      end
    end
  end
end
