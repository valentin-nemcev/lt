class Task::Relation

  include Graph::Edge

  attr_reader :type
  def initialize(attrs={})
    self.nodes.parent = attrs.fetch :supertask
    self.nodes.child = attrs.fetch :subtask
    @type = attrs.fetch :type
  end

  def dependency?
    type == :dependency
  end

  def composition?
    type == :composition
  end

end
