class TasksController < ApplicationController

  def index
    mapper = Task::Mapper.new user: current_user
    @tasks = mapper.fetch_all

    render :list
  end

  def create
    head :status => :not_implemented
  end


  def complete
    head :status => :not_implemented
  end

  def undo_complete
    head :status => :not_implemented
  end

end
