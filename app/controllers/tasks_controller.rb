class TasksController < ApplicationController
  include TasksHelper

  before_filter :get_effective_date, only: [:create, :update]

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

  before_filter :fetch_task, only: [:update, :destroy]
  attr_reader :task

  def update
    task.update_attributes task_attrs, on: effective_date
    task.update_related_tasks fetch_related_tasks(task_params),
        on: effective_date
    @tasks, @relations, @revisions =
      graph.new_events :for => task, :after => effective_date - 1.second

    storage.store task

    render :events
  end

  def destroy
    storage.destroy_task task
    head :status => :ok
  end


  protected

  def fetch_task
    @task = storage.fetch params[:id]
  rescue Task::Storage::TaskNotFoundError
    head :status => :not_found
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

  def get_effective_date
    params[:effective_date].try do |date|
      @effective_date = Time.httpdate(date).in_time_zone
    end
  rescue ArgumentError => e
    render :status => :bad_request, :text => e.message
  end

  def storage
    @storage ||= Task::Storage.new user: current_user
  end

  def graph
    @graph ||= storage.graph
  end
end
