require 'test_helper'

module Tilia
  module VObject
    # This is a unittest for Issue #53.
    class IncorrectExpandTest < Minitest::Test
      def test_expand
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foo
DTSTART:20130711T050000Z
DTEND:20130711T053000Z
RRULE:FREQ=DAILY;INTERVAL=1;COUNT=2
END:VEVENT
BEGIN:VEVENT
UID:foo
DTSTART:20130719T050000Z
DTEND:20130719T053000Z
RECURRENCE-ID:20130712T050000Z
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(input)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        vcal.expand(Time.zone.parse('2011-01-01'), Time.zone.parse('2014-01-01'))

        result = vcal.serialize

        output = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foo
DTSTART:20130711T050000Z
DTEND:20130711T053000Z
END:VEVENT
BEGIN:VEVENT
UID:foo
DTSTART:20130719T050000Z
DTEND:20130719T053000Z
RECURRENCE-ID:20130712T050000Z
END:VEVENT
END:VCALENDAR
ICS
        assert_equal(output, result.delete("\r"))
      end
    end
  end
end
