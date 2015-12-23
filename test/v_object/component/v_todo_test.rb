require 'test_helper'

module Tilia
  module VObject
    class VTodoTest < Minitest::Test
      def time_range_test_data
        tests = []

        calendar = Tilia::VObject::Component::VCalendar.new

        vtodo = calendar.create_component('VTODO')
        vtodo['DTSTART'] = '20111223T120000Z'
        tests << [vtodo, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo2 = vtodo.clone
        vtodo2['DURATION'] = 'P1D'
        tests << [vtodo2, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo2, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo3 = vtodo.clone
        vtodo3['DUE'] = '20111225'
        tests << [vtodo3, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo3, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo4 = calendar.create_component('VTODO')
        vtodo4['DUE'] = '20111225'
        tests << [vtodo4, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo4, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo5 = calendar.create_component('VTODO')
        vtodo5['COMPLETED'] = '20111225'
        tests << [vtodo5, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo5, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo6 = calendar.create_component('VTODO')
        vtodo6['CREATED'] = '20111225'
        tests << [vtodo6, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo6, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo7 = calendar.create_component('VTODO')
        vtodo7['CREATED'] = '20111225'
        vtodo7['COMPLETED'] = '20111226'
        tests << [vtodo7, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo7, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vtodo7 = calendar.create_component('VTODO')
        tests << [vtodo7, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vtodo7, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), true]

        tests
      end

      def test_in_time_range
        time_range_test_data.each do |data|
          (vtodo, start, ending, outcome) = data
          assert_equal(outcome, vtodo.in_time_range?(start, ending))
        end
      end

      def test_validate
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTODO
UID:1234-21355-123156
DTSTAMP:20140402T183400Z
END:VTODO
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal([], messages)
      end

      def test_validate_invalid
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTODO
END:VTODO
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal(
          [
            'UID MUST appear exactly once in a VTODO component',
            'DTSTAMP MUST appear exactly once in a VTODO component'
          ],
          messages
        )
      end

      def test_validate_duedtstart_mis_match
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTODO
UID:FOO
DTSTART;VALUE=DATE-TIME:20140520T131600Z
DUE;VALUE=DATE:20140520
DTSTAMP;VALUE=DATE-TIME:20140520T131600Z
END:VTODO
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal(
          [
            'The value type (DATE or DATE-TIME) must be identical for DUE and DTSTART'
          ],
          messages
        )
      end

      def test_validate_du_ebefore_dtstart
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VTODO
UID:FOO
DTSTART;VALUE=DATE:20140520
DUE;VALUE=DATE:20140518
DTSTAMP;VALUE=DATE-TIME:20140520T131600Z
END:VTODO
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal(
          [
            'DUE must occur after DTSTART'
          ],
          messages
        )
      end
    end
  end
end
