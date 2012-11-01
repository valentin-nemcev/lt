class TasksController < ApplicationController
  include TasksHelper

  rescue_from Task::Storage::TaskNotFoundError,
    with: -> { head :status => :not_found }

  before_filter :get_effective_date, only: [:create, :update]

  def index
    graph = storage.fetch_graph
    @revisions = graph.revisions
    @tasks = graph.tasks
    @relations = graph.relations

    render :events
  end

  def create
    @task = Task.new_subtype task_params[:type],
      task_attrs.merge(on: effective_date)
    @task.update_related_tasks fetch_related_tasks(task_params),
      on: effective_date

    storage.store @task
    @tasks = [@task]
    @revisions = @task.attribute_revisions
    @relations = @task.relations

    render :events, :status => :created
  rescue Task::TaskError => e
    logger.error e
    render :status => :bad_request, :json => {task_errors: [e]}
  end

  def update
    @task = storage.fetch params[:id]
    task_updates = @task.update_attributes task_attrs,
      on: effective_date

    updated_relations =
      @task.update_related_tasks fetch_related_tasks(task_params),
        on: effective_date

    storage.store @task
    @tasks = []
    @revisions = task_updates
    @relations = updated_relations

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


  protected

  def task_params
    params[:task].symbolize_keys
  end

  def task_attrs
    task_params.slice(*Task::Base.revisable_attributes)
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
end
