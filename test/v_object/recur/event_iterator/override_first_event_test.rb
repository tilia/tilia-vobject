require 'test_helper'

module Tilia
  module VObject
    class OverrideFirstEventTest < Minitest::Test
      def test_override_first_event
        input = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20140803T120000Z
RRULE:FREQ=WEEKLY
SUMMARY:Original
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140803T120000Z
DTSTART:20140803T120000Z
SUMMARY:Overridden
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(input)
        vcal.expand(Time.zone.parse('2014-08-01'), Time.zone.parse('2014-09-01'))

        expected = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140803T120000Z
DTSTART:20140803T120000Z
SUMMARY:Overridden
END:VEVENT
BEGIN:VEVENT
UID:foobar
DTSTART:20140810T120000Z
SUMMARY:Original
RECURRENCE-ID:20140810T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
DTSTART:20140817T120000Z
SUMMARY:Original
RECURRENCE-ID:20140817T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
DTSTART:20140824T120000Z
SUMMARY:Original
RECURRENCE-ID:20140824T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
DTSTART:20140831T120000Z
SUMMARY:Original
RECURRENCE-ID:20140831T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_ics = vcal.serialize
        new_ics = new_ics.delete("\r")
        assert_equal(expected, new_ics)
      end

      def test_remove_first_event
        input = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20140803T120000Z
RRULE:FREQ=WEEKLY
EXDATE:20140803T120000Z
SUMMARY:Original
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(input)
        vcal.expand(Time.zone.parse('2014-08-01'), Time.zone.parse('2014-08-19'))

        expected = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20140810T120000Z
SUMMARY:Original
RECURRENCE-ID:20140810T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
DTSTART:20140817T120000Z
SUMMARY:Original
RECURRENCE-ID:20140817T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_ics = vcal.serialize
        new_ics = new_ics.delete("\r")
        assert_equal(expected, new_ics)
      end
    end
  end
end
