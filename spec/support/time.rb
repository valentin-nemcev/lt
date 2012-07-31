# Databases and other places may truncate usecs, so we define a mathers that
# truncates usecs form dates before testing for equality

RSpec::Matchers.define(:eq_up_to_sec) do |expected|
  match do |actual|
    actual.change(usec: 0) == expected.change(usec: 0)
  end

  diffable
end

