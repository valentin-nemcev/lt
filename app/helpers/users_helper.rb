module UsersHelper
  def user_selector
    content_tag :div, :id => 'user_selector' do
      form_tag select_user_path do
        select_tag :user_id, options_from_collection_for_select(
                                          @users, :id, :name, @current_user.id)
      end
    end
  end
end
