module DateSpecHelper
  def with_frozen_time(time=nil)
    time ||= Time.current
    # Databases and other places may truncate usecs, so we truncate them too to
    # avoid problems with comparisons
    time = time.change :usec => 0
    Timecop.freeze(time) { yield time }
  end
end

RSpec.configure do |config|
  config.include DateSpecHelper

  config.around :each, :with_frozen_time do |example|
    with_frozen_time do
      example.run
    end
  end
end

