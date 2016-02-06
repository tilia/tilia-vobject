require 'test_helper'

module Tilia
  module VObject
    class UriTest < Minitest::Test
      def test_always_encode_uri_v_calendar
        # Apple iCal has issues with URL properties that don't have
        # VALUE=URI specified. We added a workaround to vobject that
        # ensures VALUE=URI always appears for these.
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
URL:http://example.org/
END:VEVENT
END:VCALENDAR
ICS
        output = Reader.read(input).serialize
        assert(output.index('URL;VALUE=URI:http://example.org/'))
      end
    end
  end
end
