require 'test_helper'

module Tilia
  module VObject
    class MissingOverriddenTest < Minitest::Test
      def test_expand
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foo
DTSTART:20130727T120000Z
DURATION:PT1H
RRULE:FREQ=DAILY;COUNT=2
SUMMARY:A
END:VEVENT
BEGIN:VEVENT
RECURRENCE-ID:20130728T120000Z
UID:foo
DTSTART:20140101T120000Z
DURATION:PT1H
SUMMARY:B
END:VEVENT
END:VCALENDAR
ICS
        vcal = Tilia::VObject::Reader.read(input)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        vcal.expand(Time.zone.parse('2011-01-01'), Time.zone.parse('2015-01-01'))

        result = vcal.serialize

        output = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foo
DTSTART:20130727T120000Z
DURATION:PT1H
SUMMARY:A
END:VEVENT
BEGIN:VEVENT
RECURRENCE-ID:20130728T120000Z
UID:foo
DTSTART:20140101T120000Z
DURATION:PT1H
SUMMARY:B
END:VEVENT
END:VCALENDAR
ICS
        assert_equal(output, result.delete("\r"))
      end
    end
  end
end
