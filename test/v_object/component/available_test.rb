require 'test_helper'

module Tilia
  module VObject
    class AvailableTest < Minitest::Test
      def test_available_component
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:AVAILABLE
END:AVAILABLE
END:VCALENDAR
VCAL
        document = Tilia::VObject::Reader.read(vcal)
        assert_kind_of(Tilia::VObject::Component::Available, document['AVAILABLE'])
      end

      def test_get_effective_start_end
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:AVAILABLE
DTSTART:20150717T162200Z
DTEND:20150717T172200Z
END:AVAILABLE
END:VCALENDAR
VCAL
        document = Tilia::VObject::Reader.read(vcal)
        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2015-07-17 16:22:00'),
            tz.parse('2015-07-17 17:22:00')
          ],
          document['AVAILABLE'].effective_start_end
        )
      end

      def test_get_effective_start_end_duration
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:AVAILABLE
DTSTART:20150717T162200Z
DURATION:PT1H
END:AVAILABLE
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2015-07-17 16:22:00'),
            tz.parse('2015-07-17 17:22:00')
          ],
          document['AVAILABLE'].effective_start_end
        )
      end
    end
  end
end
