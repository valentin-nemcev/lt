class Task::Relation

  include Graph::Edge

  attr_reader :type, :added_on, :removed_on
  def initialize(attrs={})
    self.nodes.parent = attrs.fetch :supertask
    self.nodes.child = attrs.fetch :subtask
    @type = attrs.fetch :type
    @added_on = attrs.fetch :on, Time.current
  end

  def remove(opts={})
    @removed_on = opts.fetch :on, Time.current
  end

  def dependency?
    type == :dependency
  end

  def composition?
    type == :composition
  end

  def inspect
    "#<#{self.class}: child=#{self.nodes.child.inspect}, parent=#{self.nodes.parent.inspect}, " +
      "added_on=#{self.added_on}, removed_on=#{self.removed_on}>"
  end

end
