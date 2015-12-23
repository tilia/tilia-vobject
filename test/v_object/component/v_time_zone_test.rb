require 'test_helper'

module Tilia
  module VObject
    class VTimeZoneTest < Minitest::Test
      def test_validate
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTIMEZONE
TZID:America/Toronto
END:VTIMEZONE
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal([], messages)
      end

      def test_get_time_zone
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTIMEZONE
TZID:America/Toronto
END:VTIMEZONE
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        tz = ActiveSupport::TimeZone.new('America/Toronto')

        assert_equal(tz, obj['VTIMEZONE'].time_zone)
      end
    end
  end
end
