require 'lib/spec_helper'
require 'interval'

describe Interval do
  describe '#include?' do
    example("
    123456789
      [---]
     x
    ") { Interval.new(left_closed: 3, right_closed: 7).should_not include(2) }

    example("
    123456789
      (---]
      x
    ") { Interval.new(left_open: 3, right_closed: 7).should_not include(3) }

    example("
    123456789
      [---]
       x
    ") { Interval.new(left_closed: 3, right_closed: 7).should include(4) }

    example("
    123456789
      [---)
          x
    ") { Interval.new(left_closed: 3, right_open: 7).should_not include(7) }

    example("
    123456789
      [------
          x
    ") { Interval.new(left_closed: 3, right_open: nil).should include(7) }

    example("
    123456789
    ---------
          x
    ") { Interval.new(left_open: nil, right_open: nil).should include(7) }

    example("
    123456789
    -------]
          x
    ") { Interval.new(left_open: nil, right_closed: 8).should include(7) }

    example("
    123456789
    ------)
          x
    ") { Interval.new(left_open: nil, right_open: 7).should_not include(7) }

    example("
    123456789
      (------
      x
    ") { Interval.new(left_open: 3, right_open: nil).should_not include(3) }
  end

  describe '#overlaps_with?' do
    RSpec::Matchers.define :overlap_with do |other_interval|
      match do |interval|
        interval.overlaps_with? other_interval
      end
    end

    example "
    123456789
    [--]
        [---]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 4
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should_not overlap_with iv2
      iv2.should_not overlap_with iv1
    end

    example "
    123456789
    [---]
        [---]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    [---)
        [---]
    " do
      iv1 = Interval.new left_closed: 1, right_open:   5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should_not overlap_with iv2
      iv2.should_not overlap_with iv1
    end

    example "
    123456789
    [----]
        [---]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    [------]
      [---]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    (------)
    [------]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    (------)
    (------)
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end


    example "
    123456789
    [------]
    [------]
    " do
      iv1 = Interval.new left_closed: 1, right_closed: 5
      iv2 = Interval.new left_closed: 5, right_closed: 9
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
       [-----
    -------]
    " do
      iv1 = Interval.new left_closed: 4, right_open: nil
      iv2 = Interval.new left_open: nil, right_closed: 8
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
       (-----
    -------)
    " do
      iv1 = Interval.new left_open: 4, right_open: nil
      iv2 = Interval.new left_open: nil, right_open: 8
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
       [-----
    -------]
    " do
      iv1 = Interval.new left_closed: 4, right_open: nil
      iv2 = Interval.new left_open: nil, right_closed: 8
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
       (-----
    ---)
    " do
      iv1 = Interval.new left_open: 4, right_open: nil
      iv2 = Interval.new left_open: nil, right_open: 4
      iv1.should_not overlap_with iv2
      iv2.should_not overlap_with iv1
    end

    example "
    123456789
     [-------
       [-----
    " do
      iv1 = Interval.new left_closed: 2, right_open: nil
      iv2 = Interval.new left_closed: 4, right_open: nil
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
     [-------
       [---)
    " do
      iv1 = Interval.new left_closed: 2, right_open: nil
      iv2 = Interval.new left_closed: 4, right_open: 8
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    ---------
       [---)
    " do
      iv1 = Interval.new left_open: nil, right_open: nil
      iv2 = Interval.new left_closed: 4, right_open: 8
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end

    example "
    123456789
    ---------
    ---------
    " do
      iv1 = Interval.new left_open: nil, right_open: nil
      iv2 = Interval.new left_open: nil, right_open: nil
      iv1.should overlap_with iv2
      iv2.should overlap_with iv1
    end
  end

  describe 'properties' do
    a = 0
    b = 1

    context 'open' do
      subject { Interval.new left_open: a, right_open: b }
      it { should_not be_empty }
      it { should_not be_degenerate }
      it { should     be_proper }
      it { should     be_bounded }
      it { should_not be_unbounded }

      it { should     be_open }
      it { should_not be_closed }

      it { should     be_left_open }
      it { should_not be_left_closed }
      it { should     be_left_bounded }
      it { should_not be_left_unbounded }

      it { should     be_right_open }
      it { should_not be_right_closed }
      it { should     be_right_bounded }
      it { should_not be_right_unbounded }

      its(:left_endpoint)  { should be a }
      its(:right_endpoint) { should be b }
    end

    context 'closed' do
      subject { Interval.new left_closed: a, right_closed: b }
      it { should_not be_empty }
      it { should_not be_degenerate }
      it { should     be_proper }
      it { should     be_bounded }
      it { should_not be_unbounded }

      it { should_not be_open }
      it { should     be_closed }

      it { should_not be_left_open }
      it { should     be_left_closed }
      it { should     be_left_bounded }
      it { should_not be_left_unbounded }

      it { should_not be_right_open }
      it { should     be_right_closed }
      it { should     be_right_bounded }
      it { should_not be_right_unbounded }

      its(:left_endpoint)  { should be a }
      its(:right_endpoint) { should be b }
    end

    context 'left-closed, right-open' do
      subject { Interval.new left_closed: a, right_open: b }
      it { should_not be_empty }
      it { should_not be_degenerate }
      it { should     be_proper }
      it { should     be_bounded }
      it { should_not be_unbounded }

      it { should_not be_open }
      it { should_not be_closed }

      it { should_not be_left_open }
      it { should     be_left_closed }
      it { should     be_left_bounded }
      it { should_not be_left_unbounded }

      it { should     be_right_open }
      it { should_not be_right_closed }
      it { should     be_right_bounded }
      it { should_not be_right_unbounded }

      its(:left_endpoint)  { should be a }
      its(:right_endpoint) { should be b }
    end

    context 'left-open, right-closed' do
      subject { Interval.new left_open: a, right_closed: b }
      it { should_not be_empty }
      it { should_not be_degenerate }
      it { should     be_proper }
      it { should     be_bounded }
      it { should_not be_unbounded }

      it { should_not be_open }
      it { should_not be_closed }

      it { should     be_left_open }
      it { should_not be_left_closed }
      it { should     be_left_bounded }
      it { should_not be_left_unbounded }

      it { should_not be_right_open }
      it { should     be_right_closed }
      it { should     be_right_bounded }
      it { should_not be_right_unbounded }

      its(:left_endpoint)  { should be a }
      its(:right_endpoint) { should be b }
    end

    context 'left-open, right-unbounded' do
      [
        {left_open: a, right_open:   nil},
        {left_open: a, right_closed: nil},
      ].each do |interval_def|
        context do
          subject { Interval.new interval_def }
          it { should_not be_empty }
          it { should_not be_degenerate }
          it { should     be_proper }
          it { should_not be_bounded }
          it { should_not be_unbounded }

          it { should     be_open }
          it { should_not be_closed }

          it { should     be_left_open }
          it { should_not be_left_closed }
          it { should     be_left_bounded }
          it { should_not be_left_unbounded }

          it { should     be_right_open }
          it { should_not be_right_closed }
          it { should_not be_right_bounded }
          it { should     be_right_unbounded }

          its(:left_endpoint)  { should be a }
          its(:right_endpoint) { should be nil }
        end
      end
    end

    context 'left-unbounded, right-closed' do
      [
        {left_open:   nil, right_closed: b},
        {left_closed: nil, right_closed: b},
      ].each do |interval_def|
        context do
          subject { Interval.new interval_def }
          it { should_not be_empty }
          it { should_not be_degenerate }
          it { should     be_proper }
          it { should_not be_bounded }
          it { should_not be_unbounded }

          it { should_not be_open }
          it { should_not be_closed }

          it { should     be_left_open }
          it { should_not be_left_closed }
          it { should_not be_left_bounded }
          it { should     be_left_unbounded }

          it { should_not be_right_open }
          it { should     be_right_closed }
          it { should     be_right_bounded }
          it { should_not be_right_unbounded }

          its(:left_endpoint)  { should be nil }
          its(:right_endpoint) { should be b }
        end
      end
    end

    context 'unbounded' do
      subject { Interval.new left_open: nil, right_open: nil }
      it { should_not be_empty }
      it { should_not be_degenerate }
      it { should     be_proper }
      it { should_not be_bounded }
      it { should     be_unbounded }

      it { should     be_open }
      it { should_not be_closed }

      it { should     be_left_open }
      it { should_not be_left_closed }
      it { should_not be_left_bounded }
      it { should     be_left_unbounded }

      it { should     be_right_open }
      it { should_not be_right_closed }
      it { should_not be_right_bounded }
      it { should     be_right_unbounded }

      its(:left_endpoint)  { should be nil }
      its(:right_endpoint) { should be nil }
    end


    context 'empty' do
      [
        {left_closed: b, right_closed: a},
        {left_open:   a, right_open:   a},
        {left_closed: a, right_open:   a},
        {left_open:   b, right_closed: a},
      ].each do |interval_def|
        context do
          subject { Interval.new(interval_def) }
          it { should     be_empty }
          it { should_not be_degenerate }
          it { should_not be_proper }
          it { should_not include(a) }
          it { should_not include(b) }
        end
      end
    end

    context 'degenerate' do
      subject { Interval.new(left_closed: a, right_closed: a) }
      it { should     be_degenerate }
      it { should_not be_empty }
      it { should_not be_proper }
      it { should include(a) }
    end
  end

end
