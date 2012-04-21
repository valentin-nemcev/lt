require 'spec_helper'

describe TaskMapper do
  describe '.create' do
    it 'creates tasks with given body' do
      task = TaskMapper.create body: 'hello!'
      task.body.should eq('hello!')
    end

    it 'creates tasks with default creation date' do
      with_frozen_time do |now|
        task = TaskMapper.create body: 'hello!'
        task.created_on.should eq(now)
      end
    end

    it 'creates tasks with provided creation date' do
      with_frozen_time do |now|
        task = TaskMapper.create body: 'hello!', on: 2.days.since(now)
        task.created_on.should eq(2.days.since(now))
      end
    end

    it 'creates tasks with provided project' do
      project = TaskMapper.create body: 'project!'
      task = TaskMapper.create body: 'task!', project: project
      task.project.should eq(project)
      project.subtasks.should eq([task])
    end

    it 'creates tasks with provided user' do
      user = User.create!
      task = TaskMapper.create body: 'hello!', user: user
      task.user.should eq(user)
    end

    describe 'creates tasks with valid effective date' do
      specify 'on current date' do
        with_frozen_time do |now|
          task = create_task
          task.effective_date.should eq(now)
        end
      end

      specify 'on past date' do
        with_frozen_time do |now|
          task = create_task on: 2.days.ago
          task.effective_date.should eq(now)
        end
      end

      specify 'on future date' do
        with_frozen_time do |now|
          task = create_task on: 2.days.from_now
          task.effective_date.should eq(2.days.from_now)
        end
      end
    end
  end

  def create_task(attrs={})
    attrs.merge! body: 'Test task'
    TaskMapper.create attrs
  end

  describe '.fetch_all' do
    it 'fetches tasks' do
      task1 = create_task
      task2 = create_task
      fetched_tasks = TaskMapper.fetch_all
      fetched_tasks.should =~ [task1, task2]
    end

    it 'fetches tasks for provided user' do
      user1 = User.create! login: 'user1'
      user2 = User.create! login: 'user2'
      task1 = create_task user: user1
      task2 = create_task user: user2

      fetched_tasks = TaskMapper.fetch_all for_user: user1

      fetched_tasks.should =~ [task1]
    end

    it 'fetches task as of current date by default' do
      create_task

    end
  end

  describe '.fetch_by_id' do
    it 'fetches single task by id' do
      task = create_task
      fetched_task = TaskMapper.fetch_by_id task.id

      fetched_task.should eq(task)
    end
  end

  describe '.save' do
    it 'saves task completion state' do
      task = create_task
      task.complete!
      TaskMapper.save task

      fetched_task = TaskMapper.fetch_by_id task.id
      fetched_task.should eq(task)

      task.undo_complete!
      TaskMapper.save task

      fetched_task = TaskMapper.fetch_by_id task.id
      fetched_task.should eq(task)
    end
  end
end
