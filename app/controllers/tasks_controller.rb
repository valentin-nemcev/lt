class TasksController < ApplicationController

  def create
    attrs = {
      user: current_user,
      body: params[:task][:body],
      project: TaskMapper.fetch_by_id(params[:task][:parent_id]),
    }
    task = TaskMapper.create attrs

    render json: task
  end


  def complete
    with_task do |task|
      task.complete!
    end
  end

  def undo_complete
    with_task do |task|
      task.undo_complete!
    end
  end

  protected

  def with_task
    task = TaskMapper.fetch_by_id params[:id]
    yield task
    TaskMapper.save task
    render json: task
  end
end
