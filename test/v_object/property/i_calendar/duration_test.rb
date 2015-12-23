require 'test_helper'

module Tilia
  module VObject
    class DurationTest < Minitest::Test
      def test_get_date_interval
        vcal = Tilia::VObject::Component::VCalendar.new
        event = vcal.add('VEVENT', 'DURATION' => ['PT1H'])

        assert_equal(1.hour, event['DURATION'].date_interval)
      end
    end
  end
end
