require 'test_helper'

module Tilia
  module VObject
    class Issue48Test < Minitest::Test
      def test_expand
        input = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foo
DTEND;TZID=Europe/Moscow:20130710T120000
DTSTART;TZID=Europe/Moscow:20130710T110000
RRULE:FREQ=DAILY;UNTIL=20130712T195959Z
END:VEVENT
BEGIN:VEVENT
UID:foo
DTEND;TZID=Europe/Moscow:20130713T120000
DTSTART;TZID=Europe/Moscow:20130713T110000
RECURRENCE-ID;TZID=Europe/Moscow:20130711T110000
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(input)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, 'foo')

        result = it.to_a

        tz = ActiveSupport::TimeZone.new('Europe/Moscow')

        expected = [
          tz.parse('2013-07-10 11:00:00'),
          tz.parse('2013-07-12 11:00:00'),
          tz.parse('2013-07-13 11:00:00')
        ]

        assert_equal(expected, result)
      end
    end
  end
end
