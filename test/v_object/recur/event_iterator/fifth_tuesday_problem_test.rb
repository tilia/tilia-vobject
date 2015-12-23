require 'test_helper'

module Tilia
  module VObject
    class FifthTuesdayProblemTest < Minitest::Test
      # A pretty slow test. Had to be marked as 'medium' for phpunit to not die
      # after 1 second. Would be good to optimize later.
      #
      # @medium
      def test_get_dt_end
        ics = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Apple Inc.//iCal 4.0.4//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
TRANSP:OPAQUE
DTEND;TZID=America/New_York:20070925T170000
UID:uuid
DTSTAMP:19700101T000000Z
LOCATION:
DESCRIPTION:
STATUS:CONFIRMED
SEQUENCE:18
SUMMARY:Stuff
DTSTART;TZID=America/New_York:20070925T160000
CREATED:20071004T144642Z
RRULE:FREQ=MONTHLY;INTERVAL=1;UNTIL=20071030T035959Z;BYDAY=5TU
END:VEVENT
END:VCALENDAR
ICS

        v_object = Tilia::VObject::Reader.read(ics)
        it = Tilia::VObject::Recur::EventIterator.new(v_object, v_object['VEVENT']['UID'].to_s)

        it.next while it.valid

        # If we got here, it means we were successful. The bug that was in the
        # system before would fail on the 5th tuesday of the month, if the 5th
        # tuesday did not exist.
        assert(true)
      end
    end
  end
end
