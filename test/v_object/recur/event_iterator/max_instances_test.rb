require 'test_helper'

module Tilia
  module VObject
    class MaxInstancesTest < TestCase
      def setup
        @max_recurrences = Settings.max_recurrences
        Settings.max_recurrences = 4

        super
      end

      def teardown
        Settings.max_recurrences = @max_recurrences
        super
      end

      def test_exceed_max_recurrences
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
DTSTART:20140803T120000Z
RRULE:FREQ=WEEKLY
SUMMARY:Original
END:VEVENT
END:VCALENDAR
ICS

        vcal = Reader.read(input)
        assert_raises(Recur::MaxInstancesExceededException) do
          vcal.expand(Time.zone.parse('2014-08-01'), Time.zone.parse('2014-09-01'))
        end
      end
    end
  end
end
