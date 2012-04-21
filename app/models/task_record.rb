class TaskRecord < ActiveRecord::Base
  self.table_name = 'tasks'
  class TaskDateInvalid < StandardError; end;

  has_dag_links :link_class_name => 'TaskDependency', :prefix => 'dependency'
  alias_method :blocking_tasks, :dependency_ancestors

  acts_as_nested_set
  alias_method :subtasks, :children
  alias_method :project, :parent

  attr_accessible :position, :id, :parent_id, :body

  default_scope order('lft')

  belongs_to :user

  attr_writer :position

  def position
    @position ||= current_position
  end

  after_save :move_to_position

  def move_to_position
    return unless @position
    move_to @position[:of], @position[:to].to_sym
  end

  def current_position
    if self.root?
      { to: 'root' }
    else
      { to: 'child', of: self.parent_id }
    end
  end


  def self.as_of(date)
    effective_date = self.sanitize_sql ['? AS `effective_date`', date]
    select(['tasks.*', effective_date]).where('? >= created_on', date)
  end


  def complete!(opts={})
    raise "Project could not be completed directly" if project?
    on = opts.fetch(:on, effective_date)
    self.completed_on = on
    return self
  end

  def undo_complete!
    write_attribute(:completed_on, nil)
    return self
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

  def effective_date
    @effective_date ||= if cd = attributes['effective_date']
      Time.zone.parse cd
    else
      Time.zone.now
    end
  end

  def completed
    if project?
      return leaves.all?(&:completed?) && !blocked?
    end

    if completed_on
      completed_on <= effective_date
    else
      false
    end
  end
  alias_method :completed?, :completed

  def actionable
    not project? and not completed? and not blocked?
  end
  alias_method :actionable?, :actionable

  def project?
    not leaf?
  end

  def blocked?
    not blocking_tasks.all?(&:completed?)
  end

  def as_json options = {}
    accessible_attributes = self.class.accessible_attributes.map(&:to_sym)
    options.merge! :only => accessible_attributes,
                   :methods => [:position, :completed, :actionable]
    super options
  end
end
