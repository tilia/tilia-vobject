require 'test_helper'

module Tilia
  module VObject
    # See https://github.com/fruux/sabre-vobject/issues/36
    class Issue36Test < Minitest::Test
      def test_workaround
        event = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:Titel
SEQUENCE:1
TRANSP:TRANSPARENT
RRULE:FREQ=YEARLY
LAST-MODIFIED:20130323T225737Z
DTSTAMP:20130323T225737Z
UID:1833bd44-188b-405c-9f85-1a12105318aa
CATEGORIES:Jubiläum
X-MOZ-GENERATION:3
RECURRENCE-ID;RANGE=THISANDFUTURE;VALUE=DATE:20131013
DTSTART;VALUE=DATE:20131013
CREATED:20100721T121914Z
DURATION:P1D
END:VEVENT
END:VCALENDAR
ICS

        obj = Tilia::VObject::Reader.read(event)

        # If this does not throw an exception, it's all good.
        it = Tilia::VObject::Recur::EventIterator.new(obj, '1833bd44-188b-405c-9f85-1a12105318aa')
        assert_kind_of(Tilia::VObject::Recur::EventIterator, it)
      end
    end
  end
end
