class Task < ActiveRecord::Base
  acts_as_nested_set

  attr_accessible :position, :id, :parent_id, :body, :deadline

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


  def self.for_date(date)
    current_date = self.sanitize_sql ['? AS `current_date`', date]
    select(['tasks.*', current_date]).where('? >= created_at', date)
  end


  def complete!(at = nil)
    at ||= DateTime.now
    update_attribute(:completed_at, at)
    return self
  end

  def undo_complete!
    update_attribute(:completed_at, nil)
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
    if completed_at
      completed_at <= current_date
    else
      false
    end
  end
  alias_method :completed?, :completed


  def as_json options = {}
    accessible_attributes = self.class.accessible_attributes.map(&:to_sym)
    options.merge! :only => accessible_attributes,
                   :methods => [:position, :completed]
    super options
  end
end
