RSpec::Matchers.define :be_unique do
  def duplicates(ary)
    ary.group_by{ |e| e }.select{ |e, dups| dups.length > 1 }.keys
  end

  match do |array|
    duplicates(array).empty?
  end

  failure_message_for_should do |array|
    "array has duplicated elements: #{duplicates(array)}"
  end
end
