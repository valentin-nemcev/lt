class TaskDateInvalid < StandardError; end;
class Task

  include Graph::Node

  attr_reader :effective_date, :created_on

  def initialize(attrs={})
    now = Time.current
    @created_on = attrs.fetch(:on, now)
    @effective_date = [@created_on, now].max

    if project = attrs[:project]
      add_project project
    end
  end


  def as_of(date)
    clone.tap { |t| t.effective_date = date }
  rescue TaskDateInvalid
    nil
  end

  def effective_date=(date)
    if date < self.created_on
      raise TaskDateInvalid, "Task didn't exist as of #{date}"
    end
    @effective_date = date
    return self
  end

  def blocked?
    not subtasks.all?(&:completed?)
  end

  def add_project project
    TaskRelation.new supertask: project, subtask: self, :type => :composition
  end

  def add_component_task component
    TaskRelation.new supertask: self, subtask: component, :type => :composition
  end

  def add_dependent_task dependent
    TaskRelation.new supertask: dependent, subtask: self, :type => :dependency
  end

  def add_blocking_task blocking
    TaskRelation.new supertask: self, subtask: blocking, :type => :dependency
  end

  def subtasks
    edges.outgoing.nodes
  end

  def supertasks
    edges.incoming.nodes
  end

  def blocking_tasks
    edges.outgoing.filter(&:dependency?).nodes
  end

  def dependent_tasks
    edges.incoming.filter(&:dependency?).nodes
  end

  def projects
    edges.incoming.filter(&:composition?).nodes
  end

  def component_tasks
    edges.outgoing.filter(&:composition?).nodes
  end

  protected

  def bump_effective_date date
    date || self.effective_date = Time.current
  end
end
