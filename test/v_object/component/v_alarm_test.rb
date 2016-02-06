require 'test_helper'

module Tilia
  module VObject
    class VAlarmTest < Minitest::Test
      def time_range_test_data
        tests = []

        calendar = Tilia::VObject::Component::VCalendar.new

        # Hard date and time
        valarm1 = calendar.create_component('VALARM')
        valarm1.add(
          calendar.create_property('TRIGGER', '20120312T130000Z', 'VALUE' => 'DATE-TIME')
        )

        tests << [valarm1, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-04-01 01:00:00'), true]
        tests << [valarm1, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-03-10 01:00:00'), false]

        # Relation to start time of event
        valarm2 = calendar.create_component('VALARM')
        valarm2.add(
          calendar.create_property('TRIGGER', '-P1D', 'VALUE' => 'DURATION')
        )

        vevent2 = calendar.create_component('VEVENT')
        vevent2['DTSTART'] = '20120313T130000Z'
        vevent2.add(valarm2)

        tests << [valarm2, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-04-01 01:00:00'), true]
        tests << [valarm2, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-03-10 01:00:00'), false]

        # Relation to end time of event
        valarm3 = calendar.create_component('VALARM')
        valarm3.add(calendar.create_property('TRIGGER', '-P1D', 'VALUE' => 'DURATION', 'RELATED' => 'END'))

        vevent3 = calendar.create_component('VEVENT')
        vevent3['DTSTART'] = '20120301T130000Z'
        vevent3['DTEND'] = '20120401T130000Z'
        vevent3.add(valarm3)

        tests << [valarm3, Time.zone.parse('2012-02-25 01:00:00'), Time.zone.parse('2012-03-05 01:00:00'), false]
        tests << [valarm3, Time.zone.parse('2012-03-25 01:00:00'), Time.zone.parse('2012-04-05 01:00:00'), true]

        # Relation to end time of todo
        valarm4 = calendar.create_component('VALARM')
        valarm4['TRIGGER'] = '-P1D'
        valarm4['TRIGGER']['VALUE'] = 'DURATION'
        valarm4['TRIGGER']['RELATED'] = 'END'

        vtodo4 = calendar.create_component('VTODO')
        vtodo4['DTSTART'] = '20120301T130000Z'
        vtodo4['DUE'] = '20120401T130000Z'
        vtodo4.add(valarm4)

        tests << [valarm4, Time.zone.parse('2012-02-25 01:00:00'), Time.zone.parse('2012-03-05 01:00:00'), false]
        tests << [valarm4, Time.zone.parse('2012-03-25 01:00:00'), Time.zone.parse('2012-04-05 01:00:00'), true]

        # Relation to start time of event + repeat
        valarm5 = calendar.create_component('VALARM')
        valarm5['TRIGGER'] = '-P1D'
        valarm5['TRIGGER']['VALUE'] = 'DURATION'
        valarm5['REPEAT'] = 10
        valarm5['DURATION'] = 'P1D'

        vevent5 = calendar.create_component('VEVENT')
        vevent5['DTSTART'] = '20120301T130000Z'
        vevent5.add(valarm5)

        tests << [valarm5, Time.zone.parse('2012-03-09 01:00:00'), Time.zone.parse('2012-03-10 01:00:00'), true]

        # Relation to start time of event + duration, but no repeat
        valarm6 = calendar.create_component('VALARM')
        valarm6['TRIGGER'] = '-P1D'
        valarm6['TRIGGER']['VALUE'] = 'DURATION'
        valarm6['DURATION'] = 'P1D'

        vevent6 = calendar.create_component('VEVENT')
        vevent6['DTSTART'] = '20120313T130000Z'
        vevent6.add(valarm6)

        tests << [valarm6, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-04-01 01:00:00'), true]
        tests << [valarm6, Time.zone.parse('2012-03-01 01:00:00'), Time.zone.parse('2012-03-10 01:00:00'), false]

        # Relation to end time of event (DURATION instead of DTEND)
        valarm7 = calendar.create_component('VALARM')
        valarm7['TRIGGER'] = '-P1D'
        valarm7['TRIGGER']['VALUE'] = 'DURATION'
        valarm7['TRIGGER']['RELATED'] = 'END'

        vevent7 = calendar.create_component('VEVENT')
        vevent7['DTSTART'] = '20120301T130000Z'
        vevent7['DURATION'] = 'P30D'
        vevent7.add(valarm7)

        tests << [valarm7, Time.zone.parse('2012-02-25 01:00:00'), Time.zone.parse('2012-03-05 01:00:00'), false]
        tests << [valarm7, Time.zone.parse('2012-03-25 01:00:00'), Time.zone.parse('2012-04-05 01:00:00'), true]

        # Relation to end time of event (No DTEND or DURATION)
        valarm7 = calendar.create_component('VALARM')
        valarm7['TRIGGER'] = '-P1D'
        valarm7['TRIGGER']['VALUE'] = 'DURATION'
        valarm7['TRIGGER']['RELATED'] = 'END'

        vevent7 = calendar.create_component('VEVENT')
        vevent7['DTSTART'] = '20120301T130000Z'
        vevent7.add(valarm7)

        tests << [valarm7, Time.zone.parse('2012-02-25 01:00:00'), Time.zone.parse('2012-03-05 01:00:00'), true]
        tests << [valarm7, Time.zone.parse('2012-03-25 01:00:00'), Time.zone.parse('2012-04-05 01:00:00'), false]

        tests
      end

      def test_in_time_range
        time_range_test_data.each do |data|
          (valarm, start, ending, outcome) = data
          assert_equal(outcome, valarm.in_time_range?(start, ending))
        end
      end

      def test_in_time_range_invalid_component
        calendar = Tilia::VObject::Component::VCalendar.new
        valarm = calendar.create_component('VALARM')
        valarm['TRIGGER'] = '-P1D'
        valarm['TRIGGER']['RELATED'] = 'END'

        vjournal = calendar.create_component('VJOURNAL')
        vjournal.add(valarm)

        assert_raises(InvalidDataException) do
          valarm.in_time_range?(Time.zone.parse('2012-02-25 01:00:00'), Time.zone.parse('2012-03-05 01:00:00'))
        end
      end

      # This bug was found and reported on the mailing list.
      def test_in_time_range_buggy
        input = <<BLA
BEGIN:VCALENDAR
BEGIN:VTODO
DTSTAMP:20121003T064931Z
UID:b848cb9a7bb16e464a06c222ca1f8102@examle.com
STATUS:NEEDS-ACTION
DUE:20121005T000000Z
SUMMARY:Task 1
CATEGORIES:AlarmCategory
BEGIN:VALARM
TRIGGER:-PT10M
ACTION:DISPLAY
DESCRIPTION:Task 1
END:VALARM
END:VTODO
END:VCALENDAR
BLA

        vobj = Tilia::VObject::Reader.read(input)

        assert(vobj['VTODO']['VALARM'].in_time_range?(Time.zone.parse('2012-10-01 00:00:00'), Time.zone.parse('2012-11-01 00:00:00')))
      end
    end
  end
end
