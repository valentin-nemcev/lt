require 'lib/spec_helper'
require 'time_infinity'

describe 'Forever and Never' do
  time           = Time.now
  date_time      = DateTime.now
  time_zone      = Time.find_zone!('Europe/Moscow')
  time_with_zone = ActiveSupport::TimeWithZone.new(time.utc, time_zone)
  forever        = Time::FOREVER
  never          = Time::NEVER

  [time, date_time, time_with_zone].each do |t|
    specify("Forever <=> #{t.class}") { (forever <=> t).should be +1 }
    specify("Never <=> #{t.class}")   { (never   <=> t).should be -1 }
    specify("#{t.class} <=> Forever") { (t <=> forever).should be -1 }
    specify("#{t.class} <=> Never")   { (t <=> never  ).should be +1 }
  end

  specify { forever.should == forever }
  specify { never.should == never }

  example do
    (time_with_zone..forever).should cover(forever)
    (time_with_zone...forever).should_not cover(forever)
  end

  example do
    (never..time_with_zone).should cover(never)
    (never...time_with_zone).should cover(never)
  end

  example do
    (forever..never).should_not cover(time)
  end
end
