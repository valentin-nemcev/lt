class TasksController < ApplicationController

  rescue_from Task::Storage::TaskNotFoundError,
    with: -> { head :status => :not_found }

  def index
    @tasks = storage.fetch_all

    render :list
  end

  def create
    task_params = params.fetch :task
    @task = Task.new_subtype task_params[:type], updated_attrs(task_params)

    task_params[:project_id].try do |project_id|
      project = storage.fetch project_id
      @task.add_project project
    end
    storage.store @task

    render :status => :created, :json => {task_creations: [], task_updates: []}
  rescue Task::TaskError => e
    logger.error e
    render :status => :bad_request, :json => {task_errors: [e]}
  end

  def show
    @task = storage.fetch params[:id]
    render 'task'
  end

  def update
    @task = storage.fetch params[:id]
    task_updates = task.update_attributes updated_attrs(params[:task])

    storage.store @task

    render :json => {task_updates: task_updates}
  rescue Task::TaskError => e
    render :status => :bad_request, :json => {task_errors: [e]}
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

  def updated_attrs(params)
    params.symbolize_keys.slice(*Task::Base.revisable_attributes)
  end

  def valid_new_task_states
    Task::Base.valid_new_task_states
  end
  helper_method :valid_new_task_states

  def storage
    @storage ||= Task::Storage.new user: current_user
  end
  protected :storage

end
