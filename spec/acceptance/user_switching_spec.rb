require 'spec_helper'

feature 'User switching', :acceptance do

  let(:tasks) { find('[widget=tasks]') }

  def switch_user(user_id)
    user_id = user_id.to_s
    users = find('[widget=user-selector]')
    users.find('[control=current-user]').tap do |user_control|
      unless user_control.value == user_id
        user_control.find("[value='#{user_id}']").select_option
      end
      user_control.should match_selector("[current-user='#{user_id}']")
    end
  end

  scenario 'Create tasks for different users' do
    user1 = create_test_user 'test_user_1'
    user2 = create_test_user 'test_user_2'

    visit tasks_page

    switch_user user1
    user1_task_id = create_task objective: 'User 1 task'
    tasks.should have_selector("[record=task][record-id='#{user1_task_id}']")
    tasks.should have_selector("[record=task]", count: 1)

    switch_user user2
    user2_task_id = create_task objective: 'User 2 task'
    tasks.should have_selector("[record=task][record-id='#{user2_task_id}']")
    tasks.should have_selector("[record=task]", count: 1)
  end
end
