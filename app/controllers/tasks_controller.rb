class TasksController < ApplicationController

  rescue_from Task::Storage::TaskNotFoundError,
    with: -> { head :status => :not_found }

  def index
    @tasks = storage.fetch_all

    render :list
  end

  def create
    task_params = params.fetch :task
    @task = Task.new_subtype task_params[:type],
      objective: task_params[:objective],
      state:     task_params[:state]

    task_params[:project_id].try do |project_id|
      project = storage.fetch project_id
      @task.add_project project
    end
    storage.store @task

    render 'task', :status => :created
  end

  def show
    @task = storage.fetch params[:id]
    render 'task'
  end

  def update
    @task = storage.fetch params[:id]
    params[:task][:objective].try do |objective|
      task.update_objective objective
    end
    params[:task][:state].try do |state|
      task.update_state state
    end


    storage.store @task

    render 'task'
  end

  def destroy
    @task = storage.fetch params[:id]
    storage.destroy_task @task
    head :status => :ok
  end


  def complete
    head :status => :not_implemented
  end

  def undo_complete
    head :status => :not_implemented
  end


  def task
    @task
  end
  helper_method :task

  def storage
    @storage ||= Task::Storage.new user: current_user
  end
  protected :storage

end
