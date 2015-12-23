require 'test_helper'
require 'stringio'

module Tilia
  module VObject
    class ICalendarTest < Minitest::Test
      def setup
        @version = Tilia::VObject::Version::VERSION
      end

      def create_stream(data)
        stream = StringIO.new
        stream.write(data)
        stream.rewind
        stream
      end

      def test_i_calendar_import_valid_event
        data = <<EOT
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foo
DTSTAMP:20140122T233226Z
DTSTART:20140101T070000Z
END:VEVENT
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        while object = objects.next
          to_return += object.serialize
        end
        assert_equal([], Tilia::VObject::Reader.read(to_return).validate)
      end

      def test_i_calendar_import_wrong_type
        data = <<EOT
BEGIN:VCARD
UID:foo1
END:VCARD
BEGIN:VCARD
UID:foo2
END:VCARD
EOT
        temp_file = create_stream(data)

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Splitter::ICalendar.new(temp_file) }
      end

      def test_i_calendar_import_end_of_data
        data = <<EOT
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foo
DTSTAMP:20140122T233226Z
END:VEVENT
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        while object = objects.next
          to_return += object.serialize
        end

        assert_nil(objects.next)
      end

      def test_i_calendar_import_invalid_event
        data = <<EOT
EOT
        temp_file = create_stream(data)
        assert_raises(Tilia::VObject::ParseException) { objects = Tilia::VObject::Splitter::ICalendar.new(temp_file) }
      end

      def test_i_calendar_import_multiple_valid_events
        event = []
        event << <<EOT
BEGIN:VEVENT
UID:foo1
DTSTAMP:20140122T233226Z
DTSTART:20140101T050000Z
END:VEVENT
EOT

        event << <<EOT
BEGIN:VEVENT
UID:foo2
DTSTAMP:20140122T233226Z
DTSTART:20140101T060000Z
END:VEVENT
EOT

        data = <<EOT
BEGIN:VCALENDAR
#{event[0]}
#{event[1]}
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        i = 0
        while object = objects.next
          # event[i] already includes \n
          expected = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{@version}//EN
CALSCALE:GREGORIAN
#{event[i]}END:VCALENDAR
EOT

          to_return += object.serialize
          expected = expected.gsub("\n", "\r\n")
          assert_equal(expected, object.serialize)
          i += 1
        end
        assert_equal([], Tilia::VObject::Reader.read(to_return).validate)
      end

      def test_i_calendar_import_event_without_uid
        data = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Sabre//Sabre VObject @version//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
DTSTART:20140101T040000Z
DTSTAMP:20140122T233226Z
END:VEVENT
END:VCALENDAR

EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        while object = objects.next
          to_return += object.serialize
        end

        assert_nil(objects.next)

        messages = Tilia::VObject::Reader.read(to_return).validate

        if messages.any?
          messages = messages.map { |i| i['message'] }
          fail("Validation errors: #{messages.join("\n")}")
        else
          assert_equal([], messages)
        end
      end

      def test_i_calendar_import_multiple_vtimezones_and_multiple_valid_events
        timezones = <<EOT
BEGIN:VTIMEZONE
TZID:Europe/Berlin
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
DTSTART:19810329T020000
TZNAME:MESZ
TZOFFSETTO:+0200
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
DTSTART:19961027T030000
TZNAME:MEZ
TZOFFSETTO:+0100
END:STANDARD
END:VTIMEZONE
BEGIN:VTIMEZONE
TZID:Europe/London
BEGIN:DAYLIGHT
TZOFFSETFROM:+0000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
DTSTART:19810329T010000
TZNAME:GMT+01:00
TZOFFSETTO:+0100
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0100
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
DTSTART:19961027T020000
TZNAME:GMT
TZOFFSETTO:+0000
END:STANDARD
END:VTIMEZONE
EOT

        event = []
        event << <<EOT
BEGIN:VEVENT
UID:foo1
DTSTAMP:20140122T232710Z
DTSTART:20140101T010000Z
END:VEVENT
EOT

        event << <<EOT
BEGIN:VEVENT
UID:foo2
DTSTAMP:20140122T232710Z
DTSTART:20140101T020000Z
END:VEVENT
EOT

        event << <<EOT
BEGIN:VEVENT
UID:foo3
DTSTAMP:20140122T232710Z
DTSTART:20140101T030000Z
END:VEVENT
EOT

        data = <<EOT
BEGIN:VCALENDAR
#{timezones}
#{event[0]}
#{event[1]}
#{event[2]}
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        i = 0
        while object = objects.next
          # newlines are part of the variables
          expected = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{@version}//EN
CALSCALE:GREGORIAN
#{timezones}#{event[i]}END:VCALENDAR
EOT
          expected = expected.gsub("\n", "\r\n")

          assert_equal(expected, object.serialize)
          to_return += object.serialize
          i += 1
        end

        assert_equal([], Tilia::VObject::Reader.read(to_return).validate)
      end

      def test_i_calendar_import_with_out_vtimezones
        data = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Apple Inc.//Mac OS X 10.8//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
CREATED:20120605T072109Z
UID:D6716295-C10F-4B20-82F9-E1A3026C7DCF
DTEND;VALUE=DATE:20120717
TRANSP:TRANSPARENT
SUMMARY:Start Vorbereitung
DTSTART;VALUE=DATE:20120716
DTSTAMP:20120605T072115Z
SEQUENCE:2
BEGIN:VALARM
X-WR-ALARMUID:A99EDA6A-35EB-4446-B8BC-CDA3C60C627D
UID:A99EDA6A-35EB-4446-B8BC-CDA3C60C627D
TRIGGER:-PT15H
X-APPLE-DEFAULT-ALARM:TRUE
ATTACH;VALUE=URI:Basso
ACTION:AUDIO
END:VALARM
END:VEVENT
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::ICalendar.new(temp_file)

        to_return = ''
        while object = objects.next
          to_return += object.serialize
        end

        messages = Tilia::VObject::Reader.read(to_return).validate
        assert_equal([], messages)
      end
    end
  end
end
