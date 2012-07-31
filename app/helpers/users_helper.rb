module UsersHelper
  def user_selector
    content_tag :div, :widget => 'user-selector' do
      form_tag select_user_path do
        opts = options_from_collection_for_select(@users, :id, :name,
                                             @current_user.id)
        select_tag :user_id, opts, control: 'current-user'
      end
    end
  end
end
