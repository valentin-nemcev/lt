module TaskFactoryHelper
  def create_action(attrs={})
    Action.new attrs
  end

  def create_project(attrs={})
    Project.new attrs
  end

  def create_task(attrs={})
    Task.new attrs
  end
end

RSpec.configuration.include TaskFactoryHelper

