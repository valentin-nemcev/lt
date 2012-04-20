class Task < ActiveRecord::Base
  has_dag_links :link_class_name => 'TaskDependency', :prefix => 'dependency'
  alias_method :blocking_tasks, :dependency_ancestors

  acts_as_nested_set
  alias_method :subtasks, :children

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
    current_date = self.sanitize_sql ['? AS `current_date`', date]
    select(['tasks.*', current_date]).where('? >= created_on', date)
  end


  def complete!(at = nil)
    raise "Project could not be completed directly" if project?
    at ||= DateTime.now
    update_attribute(:completed_on, at)
    return self
  end

  def undo_complete!
    update_attribute(:completed_on, nil)
    return self
  end


  def current_date
    if cd = attributes['current_date']
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
      completed_on <= current_date
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
