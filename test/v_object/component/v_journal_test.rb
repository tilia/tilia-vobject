require 'test_helper'

module Tilia
  module VObject
    class VJournalTest < Minitest::Test
      def time_range_test_data
        calendar = Tilia::VObject::Component::VCalendar.new

        tests = []

        vjournal = calendar.create_component('VJOURNAL')
        vjournal['DTSTART'] = '20111223T120000Z'
        tests << [vjournal, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vjournal, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vjournal2 = calendar.create_component('VJOURNAL')
        vjournal2['DTSTART'] = '20111223'
        vjournal2['DTSTART']['VALUE'] = 'DATE'
        tests << [vjournal2, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vjournal2, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vjournal3 = calendar.create_component('VJOURNAL')
        tests << [vjournal3, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), false]
        tests << [vjournal3, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

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
BEGIN:VJOURNAL
UID:12345678
DTSTAMP:20140402T174100Z
END:VJOURNAL
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

      def test_validate_broken
        input = <<HI
BEGIN:VCALENDAR
VERSION:2.0
PRODID:YoYo
BEGIN:VJOURNAL
UID:12345678
DTSTAMP:20140402T174100Z
URL:http://example.org/
URL:http://example.com/
END:VJOURNAL
END:VCALENDAR
HI

        obj = Tilia::VObject::Reader.read(input)

        warnings = obj.validate
        messages = []
        warnings.each do |warning|
          messages << warning['message']
        end

        assert_equal(['URL MUST NOT appear more than once in a VJOURNAL component'], messages)
      end
    end
  end
end
