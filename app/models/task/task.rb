module Task
class InvalidTaskError < StandardError;   end;
class Task

  class TaskDateInvalid < InvalidTaskError; end;

  include Graph::Node

  module EffectiveEdges
    def effective
      ed = node.effective_date
      filter do |edge|
        edge.added_on <= ed && (!edge.removed_on || edge.removed_on > ed)
      end
    end
  end

  attr_reader :effective_date, :created_on

  def initialize(attrs={})
    now = Time.current
    @created_on = attrs.fetch(:on, now)
    @effective_date = [@created_on, now].max

    edges.extend EffectiveEdges

    if project = attrs[:project]
      add_project project
    end
    attrs.fetch(:projects, []).each        { |t| add_project t }
    attrs.fetch(:dependent_tasks, []).each { |t| add_dependent_task t }
    attrs.fetch(:blocking_tasks, []).each  { |t| add_blocking_task t }
    attrs.fetch(:component_tasks, []).each { |t| add_component_task t }

    @objective_revisions = []
    update_objective attrs[:objective], on: created_on
  end

  def initialize_copy(original)
    @original = original
    super
  end

  def original
    @original or self
  end
  protected :original

  def ==(other)
    original.equal? other.original
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


  def add_project project, opts={}
    add_related_task opts.merge supertask: project, :type => :composition
  end

  def remove_project project, opts={}
    remove_related_task opts.merge supertask: project
  end

  def add_component_task component, opts={}
    add_related_task opts.merge subtask: component, :type => :composition
  end

  def remove_component_task component, opts={}
    remove_related_task opts.merge subtask: component
  end

  def add_dependent_task dependent, opts={}
    add_related_task opts.merge supertask: dependent, :type => :dependency
  end

  def remove_dependent_task dependent, opts={}
    remove_related_task opts.merge supertask: dependent
  end

  def add_blocking_task blocking, opts={}
    add_related_task opts.merge subtask: blocking, :type => :dependency
  end

  def remove_blocking_task blocking, opts={}
    remove_related_task opts.merge subtask: blocking
  end


  def add_related_task(opts)
    if opts.has_key?(:supertask)
      opts[:subtask] = self
    elsif opts.has_key?(:subtask)
      opts[:supertask] = self
    else
      raise ArgumentError, 'Sub or supertask is missing'
    end
    opts[:on] ||= self.effective_date
    Relation.new opts
  end

  def remove_related_task(opts)
    if supertask = opts.delete(:supertask)
      rel = edges.incoming.find{ |e| e.nodes.parent.equal? supertask }
    elsif subtask = opts.delete(:subtask)
      rel = edges.outgoing.find{ |e| e.nodes.child.equal? subtask }
    else
      raise ArgumentError, 'Sub or supertask is missing'
    end
    rel.remove opts if rel.present?
  end


  def relations
    edges.outgoing.to_set + edges.incoming.to_set
  end

  def subtasks
    edges.effective.outgoing.nodes
  end

  def supertasks
    edges.effective.incoming.nodes
  end

  def blocking_tasks
    edges.effective.outgoing.filter(&:dependency?).nodes
  end

  def dependent_tasks
    edges.effective.incoming.filter(&:dependency?).nodes
  end

  def projects
    edges.effective.incoming.filter(&:composition?).nodes
  end

  def component_tasks
    edges.effective.outgoing.filter(&:composition?).nodes
  end

  def inspect
    "<#{self.class}: #{self.objective} as of #{self.effective_date}>"
  end

end
end
