module Task
class InvalidTaskError < StandardError;   end;
class Task

  class TaskDateInvalid < InvalidTaskError; end;

  include Graph::Node

  attr_reader :effective_date, :created_on

  def initialize(attrs={})
    now = Time.current
    @created_on = attrs.fetch(:on, now)
    @effective_date = [@created_on, now].max

    if project = attrs[:project]
      add_project project
    end

    @objective_revisions = []
    update_objective attrs[:objective], on: created_on
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


  def update_objective objective, opts={}
    updated_on = opts.fetch :on, effective_date
    obj_last_updated_on = @objective_revisions.map(&:updated_on).max
    if obj_last_updated_on && updated_on < obj_last_updated_on
      raise InvalidTaskError, 'Objective updates should be in chronological order'
    end
    @objective_revisions << ObjectiveRevision.new(self, objective, updated_on)
    return self
  end

  def objective_revisions
    @objective_revisions.select { |r| r.updated_on <= effective_date }
  end

  def objective
    objective_revisions.max_by{ |r| r.updated_on }.objective
  end


  def blocked?
    not subtasks.all?(&:completed?)
  end


  def add_project project
    Relation.new supertask: project, subtask: self, :type => :composition
  end

  def add_component_task component
    Relation.new supertask: self, subtask: component, :type => :composition
  end

  def add_dependent_task dependent
    Relation.new supertask: dependent, subtask: self, :type => :dependency
  end

  def add_blocking_task blocking
    Relation.new supertask: self, subtask: blocking, :type => :dependency
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

end
end
