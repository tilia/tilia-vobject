require 'test_helper'

module Tilia
  module VObject
    class NoInstancesTest < Minitest::Test
      def test_recurrence
        input = <<ICS
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
BEGIN:VEVENT
DTSTART;TZID=Europe/Berlin:20130329T140000
DTEND;TZID=Europe/Berlin:20130329T153000
RRULE:FREQ=WEEKLY;BYDAY=FR;UNTIL=20130412T115959Z
EXDATE;TZID=Europe/Berlin:20130405T140000
EXDATE;TZID=Europe/Berlin:20130329T140000
DTSTAMP:20140916T201215Z
UID:foo
SEQUENCE:1
SUMMARY:foo
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(input)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        assert_raises(Tilia::VObject::Recur::NoInstancesException) { Tilia::VObject::Recur::EventIterator.new(vcal, 'foo') }
      end
    end
  end
end
