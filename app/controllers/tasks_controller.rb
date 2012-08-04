class TasksController < ApplicationController

  rescue_from Task::Mapper::TaskNotFoundError,
    with: -> { head :status => :not_found }

  def index
    @tasks = mapper.fetch_all

    render :list
  end

  def create
    task_params = params.fetch :task
    @task = Task.new_subtype task_params[:type],
      objective: task_params[:objective]
    mapper.store @task

    render 'task', :status => :created
  end

  def show
    @task = mapper.fetch params[:id]
    render 'task'
  end

  def update
    @task = mapper.fetch params[:id]
    params[:task][:objective].try do |objective|
      task.update_objective objective
    end

    mapper.store @task

    render 'task'
  end

  def destroy
    @task = mapper.fetch params[:id]
    mapper.destroy @task
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

  def mapper
    @mapper ||= Task::Mapper.new user: current_user
  end
  protected :mapper

end
