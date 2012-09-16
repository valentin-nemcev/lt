class TasksController < ApplicationController

  rescue_from Task::Storage::TaskNotFoundError,
    with: -> { head :status => :not_found }

  def index
    graph = storage.fetch_graph
    @revisions = graph.revisions
    @tasks = graph.tasks

    render :events
  end

  before_filter :get_effective_date, only: [:create, :update]

  def create
    task_params = params.fetch :task
    @task = Task.new_subtype task_params[:type],
      updated_attrs(task_params).merge(on: effective_date)

    task_params[:project_id].try do |project_id|
      project = storage.fetch project_id
      @task.add_project project
    end
    storage.store @task
    @tasks = [@task]
    @revisions = @task.attribute_revisions
    render :events, :status => :created
  rescue Task::TaskError => e
    logger.error e
    render :status => :bad_request, :json => {task_errors: [e]}
  end

  def update
    @task = storage.fetch params[:id]
    task_updates = @task.update_attributes updated_attrs(params[:task]),
      on: effective_date

    storage.store @task
    @tasks = []
    @revisions = task_updates
    render :events
  rescue Task::TaskError => e
    logger.error e
    render :status => :bad_request, :json => {task_errors: [e]}
  end

  def destroy
    @task = storage.fetch params[:id]
    storage.destroy_task @task
    head :status => :ok
  end


  def updated_attrs(params)
    params.symbolize_keys.slice(*Task::Base.revisable_attributes)
  end

  def effective_date
    @effective_date ||= Time.current
  end

  def get_effective_date
    params[:effective_date].try do |date|
      @effective_date = Time.httpdate(date).in_time_zone
    end
  rescue ArgumentError => e
    render :status => :bad_request, :text => e.message
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
