class TasksController < ApplicationController
  include TasksHelper


  def index
    storage.fetch_all
    @tasks, @relations, @revisions = graph.all_events

    render :events
  end

  # TODO: Remove effective_date - 1.second hack
  def create
    task = graph.new_task task_attrs.merge(on: effective_date)

    task.update_related_tasks fetch_related_tasks(task_params),
      on: effective_date

    @tasks, @relations, @revisions =
      graph.new_events :for => task, :after => effective_date - 1.second

    storage.store task

    render :events, :status => :created
  end

  def update
    task = fetch_task
    task.update_attributes task_attrs, on: effective_date
    task.update_related_tasks fetch_related_tasks(task_params),
        on: effective_date
    @tasks, @relations, @revisions =
      graph.new_events :for => task, :after => effective_date - 1.second

    storage.store task

    render :events
  end

  def destroy
    task = fetch_task
    storage.destroy_task task
    head :status => :ok
  end


  protected

  def fetch_task
    storage.fetch params[:id]
  # rescue Task::Storage::TaskNotFoundError
  #   head :status => :not_found
  end


  def task_params
    params[:task].symbolize_keys
  end

  def task_attrs
    task_params.slice(*Task::Base.editable_attributes)
  end

  def effective_date
    @effective_date ||= Time.current
  end

  def beginning_date
    @beginning_date ||= effective_date - 1.day
  end

  def effective_interval
    @effective_interval ||= TimeInterval.beginning_on beginning_date
  end


  before_filter :get_beginning_date
  def get_beginning_date
    params[:beginning_date].try do |date|
      @beginning_date = Time.httpdate(date).in_time_zone
    end
  rescue ArgumentError => e
    render :status => :bad_request, :text => e.message
  end

  before_filter :get_effective_date, only: [:create, :update]
  def get_effective_date
    params[:effective_date].try do |date|
      @effective_date = Time.httpdate(date).in_time_zone
    end
  rescue ArgumentError => e
    render :status => :bad_request, :text => e.message
  end

  def storage
    @storage ||= Task::Storage.new :user => current_user,
      :effective_in => effective_interval
  end

  def graph
    @graph ||= storage.graph
  end
end
