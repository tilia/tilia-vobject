require 'test_helper'

module Tilia
  module VObject
    class VCalendarTest < TestCase
      def assert_validate(ics, options, expected_level, expected_message = nil)
        vcal = Tilia::VObject::Reader.read(ics)
        result = vcal.validate(options)

        assert_validate_result(result, expected_level, expected_message)
      end

      def assert_validate_result(input, expected_level, expected_message = nil)
        messages = []
        input.each do |warning|
          messages << warning['message']
        end

        if expected_level == 0
          assert_equal(0, input.size, "No validation messages were expected. We got: #{messages.join(', ')}")
        else
          assert_equal(1, input.size, "We expected exactly 1 validation message, We got: #{messages.join(', ')}")
          assert_equal(expected_message, input[0]['message'])
          assert_equal(expected_level, input[0]['level'])
        end
      end

      def expand_data
        tests = []

        # No data
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
END:VCALENDAR
'

        output = input
        tests << [input, output]

        # Simple events
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla
SUMMARY:InExpand
DTSTART;VALUE=DATE:20111202
END:VEVENT
BEGIN:VEVENT
UID:bla2
SUMMARY:NotInExpand
DTSTART;VALUE=DATE:20120101
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla
SUMMARY:InExpand
DTSTART;VALUE=DATE:20111202
END:VEVENT
END:VCALENDAR
'

        tests << [input, output]

        # Removing timezone info
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Paris
END:VTIMEZONE
BEGIN:VEVENT
UID:bla4
SUMMARY:RemoveTZ info
DTSTART;TZID=Europe/Paris:20111203T130102
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla4
SUMMARY:RemoveTZ info
DTSTART:20111203T120102Z
END:VEVENT
END:VCALENDAR
'

        tests << [input, output]

        # Removing timezone info from sub-components. See Issue #278
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Paris
END:VTIMEZONE
BEGIN:VEVENT
UID:bla4
SUMMARY:RemoveTZ info
DTSTART;TZID=Europe/Paris:20111203T130102
BEGIN:VALARM
TRIGGER;VALUE=DATE-TIME;TZID=America/New_York:20151209T133200
END:VALARM
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla4
SUMMARY:RemoveTZ info
DTSTART:20111203T120102Z
BEGIN:VALARM
TRIGGER;VALUE=DATE-TIME:20151209T183200Z
END:VALARM
END:VEVENT
END:VCALENDAR
'

        tests << [input, output]

        # Recurrence rule
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111125T120000Z
DTEND:20111125T130000Z
RRULE:FREQ=WEEKLY
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111202T120000Z
DTEND:20111202T130000Z
RECURRENCE-ID:20111202T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111209T120000Z
DTEND:20111209T130000Z
RECURRENCE-ID:20111209T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111216T120000Z
DTEND:20111216T130000Z
RECURRENCE-ID:20111216T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111223T120000Z
DTEND:20111223T130000Z
RECURRENCE-ID:20111223T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule
DTSTART:20111230T120000Z
DTEND:20111230T130000Z
RECURRENCE-ID:20111230T120000Z
END:VEVENT
END:VCALENDAR
'

        tests << [input, output]

        # Recurrence rule + override
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule2
DTSTART:20111125T120000Z
DTEND:20111125T130000Z
RRULE:FREQ=WEEKLY
END:VEVENT
BEGIN:VEVENT
UID:bla6
RECURRENCE-ID:20111209T120000Z
DTSTART:20111209T140000Z
DTEND:20111209T150000Z
SUMMARY:Override!
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule2
DTSTART:20111202T120000Z
DTEND:20111202T130000Z
RECURRENCE-ID:20111202T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
RECURRENCE-ID:20111209T120000Z
DTSTART:20111209T140000Z
DTEND:20111209T150000Z
SUMMARY:Override!
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule2
DTSTART:20111216T120000Z
DTEND:20111216T130000Z
RECURRENCE-ID:20111216T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule2
DTSTART:20111223T120000Z
DTEND:20111223T130000Z
RECURRENCE-ID:20111223T120000Z
END:VEVENT
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule2
DTSTART:20111230T120000Z
DTEND:20111230T130000Z
RECURRENCE-ID:20111230T120000Z
END:VEVENT
END:VCALENDAR
'

        tests << [input, output]

        # Floating dates and times.
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:bla1
DTSTART:20141112T195000
END:VEVENT
BEGIN:VEVENT
UID:bla2
DTSTART;VALUE=DATE:20141112
END:VEVENT
BEGIN:VEVENT
UID:bla3
DTSTART;VALUE=DATE:20141112
RRULE:FREQ=DAILY;COUNT=2
END:VEVENT
END:VCALENDAR
ICS

        output = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:bla1
DTSTART:20141112T225000Z
END:VEVENT
BEGIN:VEVENT
UID:bla2
DTSTART;VALUE=DATE:20141112
END:VEVENT
BEGIN:VEVENT
UID:bla3
DTSTART;VALUE=DATE:20141112
END:VEVENT
BEGIN:VEVENT
UID:bla3
DTSTART;VALUE=DATE:20141113
RECURRENCE-ID;VALUE=DATE:20141113
END:VEVENT
END:VCALENDAR
ICS

        tests << [input, output, 'America/Argentina/Buenos_Aires', '2014-01-01', '2015-01-01']

        # Recurrence rule with no valid instances
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
UID:bla6
SUMMARY:Testing RRule3
DTSTART:20111125T120000Z
DTEND:20111125T130000Z
RRULE:FREQ=WEEKLY;COUNT=1
EXDATE:20111125T120000Z
END:VEVENT
END:VCALENDAR
'

        output = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
END:VCALENDAR
'

        tests << [input, output]
        tests
      end

      def test_expand
        expand_data.each do |data|
          (input, output, time_zone, start, ending) = data
          time_zone = 'UTC' unless time_zone
          start = '2011-12-01' unless start
          ending = '2011-12-31' unless ending

          vcal = Tilia::VObject::Reader.read(input)
          time_zone = ActiveSupport::TimeZone.new(time_zone)

          vcal = vcal.expand(
            Time.zone.parse(start),
            Time.zone.parse(ending),
            time_zone
          )

          # This will normalize the output
          output = Tilia::VObject::Reader.read(output).serialize

          assert_v_obj_equals(output, vcal.serialize)
        end
      end

      def test_broken_event_expand
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
RRULE:FREQ=WEEKLY
DTSTART;VALUE=DATE:20111202
END:VEVENT
END:VCALENDAR
'
        vcal = Tilia::VObject::Reader.read(input)

        assert_raises(InvalidDataException) do
          vcal.expand(Time.zone.parse('2011-12-01'), Time.zone.parse('2011-12-31'))
        end
      end

      def test_get_document_type
        vcard = Tilia::VObject::Component::VCalendar.new
        vcard['VERSION'] = '2.0'
        assert_equal(Tilia::VObject::Component::VCalendar::ICALENDAR20, vcard.document_type)
      end

      def test_validate_correct
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
PRODID:foo
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
DTSTAMP:20140122T233226Z
UID:foo
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal([], vcal.validate)
      end

      def test_validate_no_version
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:foo
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_wrong_version
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:3.0
PRODID:foo
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_no_prod_id
        input = 'BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_double_cal_scale
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
CALSCALE:GREGORIAN
CALSCALE:GREGORIAN
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_double_method
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
METHOD:REQUEST
METHOD:REQUEST
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_two_master_events
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
METHOD:REQUEST
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(1, vcal.validate.size)
      end

      def test_validate_one_master_event
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
METHOD:REQUEST
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
RECURRENCE-ID;VALUE=DATE:20111202
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)
        assert_equal(0, vcal.validate.size)
      end

      def test_get_base_component
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
METHOD:REQUEST
BEGIN:VEVENT
SUMMARY:test
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
RECURRENCE-ID;VALUE=DATE:20111202
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)

        result = vcal.base_component
        assert_equal('test', result['SUMMARY'].value)
      end

      def test_get_base_component_no_result
        input = 'BEGIN:VCALENDAR
VERSION:2.0
PRODID:foo
METHOD:REQUEST
BEGIN:VEVENT
SUMMARY:test
RECURRENCE-ID;VALUE=DATE:20111202
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20111202
UID:foo
DTSTAMP:20140122T234434Z
RECURRENCE-ID;VALUE=DATE:20111202
END:VEVENT
END:VCALENDAR
'

        vcal = Tilia::VObject::Reader.read(input)

        result = vcal.base_component
        assert_nil(result)
      end

      def test_no_components
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:vobject
END:VCALENDAR
ICS

        assert_validate(
          input,
          0,
          3,
          'An iCalendar object must have at least 1 component.'
        )
      end

      def test_cal_dav_no_components
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:vobject
BEGIN:VTIMEZONE
TZID:America/Toronto
END:VTIMEZONE
END:VCALENDAR
ICS

        assert_validate(
          input,
          Tilia::VObject::Component::VCalendar::PROFILE_CALDAV,
          3,
          'A calendar object on a CalDAV server must have at least 1 component (VTODO, VEVENT, VJOURNAL).'
        )
      end

      def test_cal_dav_multi_uid
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:vobject
BEGIN:VEVENT
UID:foo
DTSTAMP:20150109T184500Z
DTSTART:20150109T184500Z
END:VEVENT
BEGIN:VEVENT
UID:bar
DTSTAMP:20150109T184500Z
DTSTART:20150109T184500Z
END:VEVENT
END:VCALENDAR
ICS

        assert_validate(
          input,
          Tilia::VObject::Component::VCalendar::PROFILE_CALDAV,
          3,
          'A calendar object on a CalDAV server may only have components with the same UID.'
        )
      end

      def test_cal_dav_multi_component
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:vobject
BEGIN:VEVENT
UID:foo
RECURRENCE-ID:20150109T185200Z
DTSTAMP:20150109T184500Z
DTSTART:20150109T184500Z
END:VEVENT
BEGIN:VTODO
UID:foo
DTSTAMP:20150109T184500Z
DTSTART:20150109T184500Z
END:VTODO
END:VCALENDAR
ICS

        assert_validate(
          input,
          Tilia::VObject::Component::VCalendar::PROFILE_CALDAV,
          3,
          'A calendar object on a CalDAV server may only have 1 type of component (VEVENT, VTODO or VJOURNAL).'
        )
      end

      def test_cal_davmethod
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:vobject
BEGIN:VEVENT
UID:foo
RECURRENCE-ID:20150109T185200Z
DTSTAMP:20150109T184500Z
DTSTART:20150109T184500Z
END:VEVENT
END:VCALENDAR
ICS

        assert_validate(
          input,
          Tilia::VObject::Component::VCalendar::PROFILE_CALDAV,
          3,
          'A calendar object on a CalDAV server MUST NOT have a METHOD property.'
        )
      end
    end
  end
end
