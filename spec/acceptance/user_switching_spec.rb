require 'spec_helper'

feature 'User switching', :acceptance do

  let(:tasks) { find('[widget=tasks]') }

  def switch_user(user)
    users = find('[widget=user-selector]')
    users.find('[control=current-user]').find("[value='#{user}']").select_option
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
