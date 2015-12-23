require 'test_helper'
require 'v_object/test_case'

module Tilia
  module VObject
    class FreeBusyGeneratorTest < TestCase
      # This function takes a list of objects (icalendar objects), and turns
      # them into a freebusy report.
      #
      # Then it takes the expected output and compares it to what we actually
      # got.
      #
      # It only generates the freebusy report for the following time-range:
      # 2011-01-01 11:00:00 until 2011-01-03 11:11:11
      #
      # @param string expected
      # @param array input
      # @param string|null time_zone
      # @param string vavailability
      # @return void
      def assert_free_busy_report(expected, input, time_zone = nil, vavailability = nil)
        utc = ActiveSupport::TimeZone.new('UTC')
        gen = Tilia::VObject::FreeBusyGenerator.new(
          utc.parse('20110101T110000Z'),
          utc.parse('20110103T110000Z'),
          input,
          time_zone
        )

        if vavailability
          if vavailability.is_a?(String)
            vavailability = Tilia::VObject::Reader.read(vavailability)
          end
          gen.v_availability = vavailability
        end

        output = gen.result

        # Removing DTSTAMP because it changes every time.
        output['VFREEBUSY'].delete('DTSTAMP')

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VFREEBUSY
DTSTART:20110101T110000Z
DTEND:20110103T110000Z
#{expected}
END:VFREEBUSY
END:VCALENDAR
ICS

        assert_v_obj_equals(expected, output)
      end

      def test_generator_base_object
        obj = Tilia::VObject::Component::VCalendar.new
        obj['METHOD'] = 'PUBLISH'

        gen = Tilia::VObject::FreeBusyGenerator.new
        gen.objects = []
        gen.base_object = obj

        result = gen.result

        assert_equal('PUBLISH', result['METHOD'].value)
      end

      def test_invalid_arg
        assert_raises(ArgumentError) do
          Tilia::VObject::FreeBusyGenerator.new(
            Time.zone.parse('2012-01-01'),
            Time.zone.parse('2012-12-31'),
            Class.new
          )
        end
      end

      def test_simple
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T120000Z/20110101T130000Z',
          blob
        )
      end

      # Testing TRANSP:OPAQUE
      def test_opaque
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar2
TRANSP:OPAQUE
DTSTART:20110101T130000Z
DTEND:20110101T140000Z
END:VEVENT
END:VCALENDAR
ICS
        assert_free_busy_report(
          'FREEBUSY:20110101T130000Z/20110101T140000Z',
          blob
        )
      end

      # Testing TRANSP:TRANSPARENT
      def test_transparent
        # transparent, hidden
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar3
TRANSP:TRANSPARENT
DTSTART:20110101T140000Z
DTEND:20110101T150000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # Testing STATUS:CANCELLED
      def test_cancelled
        # transparent, hidden
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar4
STATUS:CANCELLED
DTSTART:20110101T160000Z
DTEND:20110101T170000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # Testing STATUS:TENTATIVE
      def test_tentative
        # tentative, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar5
STATUS:TENTATIVE
DTSTART:20110101T180000Z
DTEND:20110101T190000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY;FBTYPE=BUSY-TENTATIVE:20110101T180000Z/20110101T190000Z',
          blob
        )
      end

      # Testing an event that falls outside of the report time-range.
      def test_outside_time_range
        # outside of time-range, hidden
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar6
DTSTART:20110101T090000Z
DTEND:20110101T100000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # Testing an event that falls outside of the report time-range.
      def test_outside_time_range2
        # outside of time-range, hidden
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar7
DTSTART:20110104T090000Z
DTEND:20110104T100000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # Testing an event that uses DURATION
      def test_duration
        # using duration, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar8
DTSTART:20110101T190000Z
DURATION:PT1H
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T190000Z/20110101T200000Z',
          blob
        )
      end

      # Testing an all-day event
      def test_all_day
        # Day-long event, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar9
DTSTART;VALUE=DATE:20110102
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110102T000000Z/20110103T000000Z',
          blob
        )
      end

      # Testing an event that has no end or duration.
      def test_no_duration
        # No duration, does not show up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar10
DTSTART:20110101T200000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # Testing feeding the freebusy generator an object instead of a string.
      def test_object
        # encoded as object, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar11
DTSTART:20110101T210000Z
DURATION:PT1H
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T210000Z/20110101T220000Z',
          Tilia::VObject::Reader.read(blob)
        )
      end

      # Testing feeding VFREEBUSY objects instead of VEVENT
      def test_v_free_busy
        # Freebusy. Some parts show up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VFREEBUSY
FREEBUSY:20110103T010000Z/20110103T020000Z
FREEBUSY;FBTYPE=FREE:20110103T020000Z/20110103T030000Z
FREEBUSY:20110103T030000Z/20110103T040000Z,20110103T040000Z/20110103T050000Z
FREEBUSY:20120101T000000Z/20120101T010000Z
FREEBUSY:20110103T050000Z/PT1H
END:VFREEBUSY
END:VCALENDAR
ICS

        assert_free_busy_report(
          "FREEBUSY:20110103T010000Z/20110103T020000Z\n" \
              'FREEBUSY:20110103T030000Z/20110103T060000Z',
          blob
        )
      end

      def test_yearly_recurrence
        # Yearly recurrence rule, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar13
DTSTART:20100101T220000Z
DTEND:20100101T230000Z
RRULE:FREQ=YEARLY
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T220000Z/20110101T230000Z',
          blob
        )
      end

      def test_yearly_recurrence_duration
        # Yearly recurrence rule + duration, shows up
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar14
DTSTART:20100101T230000Z
DURATION:PT1H
RRULE:FREQ=YEARLY
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T230000Z/20110102T000000Z',
          blob
        )
      end

      def test_floating_time
        # Floating time, no timezone
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20110101T120000
DTEND:20110101T130000
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T120000Z/20110101T130000Z',
          blob
        )
      end

      def test_floating_time_reference_time_zone
        # Floating time + reference timezone
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20110101T120000
DTEND:20110101T130000
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T170000Z/20110101T180000Z',
          blob,
          ActiveSupport::TimeZone.new('America/Toronto')
        )
      end

      def test_all_day2
        # All-day event, slightly outside of the VFREEBUSY range.
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART;VALUE=DATE:20110101
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T110000Z/20110102T000000Z',
          blob
        )
      end

      def test_all_day_reference_time_zone
        # All-day event + reference timezone
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART;VALUE=DATE:20110101
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T110000Z/20110102T050000Z',
          blob,
          ActiveSupport::TimeZone.new('America/Toronto')
        )
      end

      def test_no_valid_instances
        # Recurrence rule with no valid instances
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20110101T100000Z
DTEND:20110103T120000Z
RRULE:FREQ=WEEKLY;COUNT=1
EXDATE:20110101T100000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_free_busy_report(
          '',
          blob
        )
      end

      # This VAVAILABILITY object overlaps with the time-range, but we're just
      # busy the entire time.
      def test_v_availability_simple
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:lalala
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        vavail = <<ICS
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20110101T000000Z
DTEND:20120101T000000Z
BEGIN:AVAILABLE
DTSTART:20110101T000000Z
DTEND:20110101T010000Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
ICS

        assert_free_busy_report(
          "FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:20110101T110000Z/20110101T120000Z\n" \
          "FREEBUSY:20110101T120000Z/20110101T130000Z\n" \
          'FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:20110101T130000Z/20110103T110000Z',
          blob,
          nil,
          vavail
        )
      end

      # This VAVAILABILITY object does not overlap at all with the freebusy
      # report, so it should be ignored.
      def test_v_availability_irrelevant
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:lalala
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        vavail = <<ICS
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20150101T000000Z
DTEND:20160101T000000Z
BEGIN:AVAILABLE
DTSTART:20150101T000000Z
DTEND:20150101T010000Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T120000Z/20110101T130000Z',
          blob,
          nil,
          vavail
        )
      end

      # This VAVAILABILITY object has a 9am-5pm AVAILABLE object for office
      # hours.
      def test_v_availability_office_hours
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:lalala
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        vavail = <<ICS
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20100101T000000Z
DTEND:20120101T000000Z
BUSYTYPE:BUSY-TENTATIVE
BEGIN:AVAILABLE
DTSTART:20101213T090000Z
DTEND:20101213T170000Z
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
ICS

        assert_free_busy_report(
          "FREEBUSY;FBTYPE=BUSY-TENTATIVE:20110101T110000Z/20110101T120000Z\n" \
          "FREEBUSY:20110101T120000Z/20110101T130000Z\n" \
          "FREEBUSY;FBTYPE=BUSY-TENTATIVE:20110101T130000Z/20110103T090000Z\n",
          blob,
          nil,
          vavail
        )
      end

      # This test has the same office hours, but has a vacation blocked off for
      # the relevant time, using a higher priority. (lower number).
      def test_v_availability_office_hours_vacation
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:lalala
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        vavail = <<ICS
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20100101T000000Z
DTEND:20120101T000000Z
BUSYTYPE:BUSY-TENTATIVE
PRIORITY:2
BEGIN:AVAILABLE
DTSTART:20101213T090000Z
DTEND:20101213T170000Z
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
END:AVAILABLE
END:VAVAILABILITY
BEGIN:VAVAILABILITY
PRIORITY:1
DTSTART:20101214T000000Z
DTEND:20110107T000000Z
BUSYTYPE:BUSY
END:VAVAILABILITY
END:VCALENDAR
ICS

        assert_free_busy_report(
          'FREEBUSY:20110101T110000Z/20110103T110000Z',
          blob,
          nil,
          vavail
        )
      end

      # This test has the same input as the last, except somebody mixed up the
      # PRIORITY values.
      #
      # The end-result is that the vacation VAVAILABILITY is completely ignored.
      def test_v_availability_office_hours_vacation2
        blob = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:lalala
DTSTART:20110101T120000Z
DTEND:20110101T130000Z
END:VEVENT
END:VCALENDAR
ICS

        vavail = <<ICS
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20100101T000000Z
DTEND:20120101T000000Z
BUSYTYPE:BUSY-TENTATIVE
PRIORITY:1
BEGIN:AVAILABLE
DTSTART:20101213T090000Z
DTEND:20101213T170000Z
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
END:AVAILABLE
END:VAVAILABILITY
BEGIN:VAVAILABILITY
PRIORITY:2
DTSTART:20101214T000000Z
DTEND:20110107T000000Z
BUSYTYPE:BUSY
END:VAVAILABILITY
END:VCALENDAR
ICS

        assert_free_busy_report(
          "FREEBUSY;FBTYPE=BUSY-TENTATIVE:20110101T110000Z/20110101T120000Z\n" \
          "FREEBUSY:20110101T120000Z/20110101T130000Z\n" \
          "FREEBUSY;FBTYPE=BUSY-TENTATIVE:20110101T130000Z/20110103T090000Z\n",
          blob,
          nil,
          vavail
        )
      end
    end
  end
end
