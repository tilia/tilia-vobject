require 'test_helper'

module Tilia
  module VObject
    class Issue26Test < Minitest::Test
      def test_expand
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:bae5d57a98
RRULE:FREQ=MONTHLY;BYDAY=0MO,0TU,0WE,0TH,0FR;INTERVAL=1
DTSTART;VALUE=DATE:20130401
DTEND;VALUE=DATE:20130402
END:VEVENT
END:VCALENDAR
ICS
        vcal = Tilia::VObject::Reader.read(input)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        assert_raises(ArgumentError) { Tilia::VObject::Recur::EventIterator.new(vcal, 'bae5d57a98') }
      end
    end
  end
end
