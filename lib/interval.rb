class Interval


  def self.infinite
    @infinite ||= new left_open: nil, right_open: nil
  end

  def initialize(endpoints = {})
    @left_endpoint  = endpoints[:left_open]  || endpoints[:left_closed]
    @right_endpoint = endpoints[:right_open] || endpoints[:right_closed]

    @left_open  = left_unbounded?  || endpoints.has_key?(:left_open)
    @right_open = right_unbounded? || endpoints.has_key?(:right_open)
  end
  attr_reader :left_endpoint, :right_endpoint

  def inspect
    lb = left_open?  ? '(' : '['
    rb = right_open? ? ')' : ']'
    "#<Interval #{lb}#{left_endpoint.inspect}, #{right_endpoint.inspect}#{rb}>"
  end

  def overlaps_with?(other)
    self.include_left?(
      other.left_endpoint, other.left_open?, other.left_unbounded?) &&
      self.include_right?(
        other.right_endpoint, other.right_open?, other.right_unbounded?)
  end

  def include?(el)
    include_left?(el) && include_right?(el)
  end

  def include_left?(el, el_open = false, el_unbounded = false)
    right_unbounded? or el_unbounded or if right_open? || el_open
      right_endpoint > el
    else
      right_endpoint >= el
    end
  end

  def include_right?(el, el_open = false, el_unbounded = false)
    left_unbounded? or el_unbounded or if left_open? || el_open
      left_endpoint < el
    else
      left_endpoint <= el
    end
  end

  def proper?
    !empty? && !degenerate?
  end

  def empty?
    !overlaps_with? self
  end

  def degenerate?
    closed? && left_endpoint == right_endpoint
  end

  def open?
    left_open? && right_open?
  end

  def closed?
    left_closed? && right_closed?
  end

  def bounded?
    left_bounded? && right_bounded?
  end

  def unbounded?
    left_unbounded? && right_unbounded?
  end

  def left_unbounded?
    @left_endpoint.nil?
  end

  def right_unbounded?
    @right_endpoint.nil?
  end

  def left_bounded?
    !left_unbounded?
  end

  def right_bounded?
    !right_unbounded?
  end

  def left_open?
    @left_open
  end

  def right_open?
    @right_open
  end

  def left_closed?
    not @left_open
  end

  def right_closed?
    not @right_open
  end
end
