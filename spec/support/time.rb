# Databases and other places may truncate usecs, so we define a mathers that
# truncates usecs form dates before testing for equality

RSpec::Matchers.define(:eq_up_to_sec) do |expected|
  match do |actual|
    actual.try(:change, usec: 0) == expected.try(:change, usec: 0)
  end

  diffable
end

