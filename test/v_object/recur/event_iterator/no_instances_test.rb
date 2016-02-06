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

        vcal = Reader.read(input)
        assert_kind_of(Component::VCalendar, vcal)

        assert_raises(Recur::NoInstancesException) do
          Recur::EventIterator.new(vcal, 'foo')
        end
      end
    end
  end
end
