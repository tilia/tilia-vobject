require 'test_helper'
require 'v_object/i_tip/broker_tester'

module Tilia
  module VObject
    class BrokerProcessMessageTest < ITip::BrokerTester
      def test_request_new
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
SEQUENCE:1
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SEQUENCE:1
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        process(itip, nil, expected)
      end

      def test_request_update
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
SEQUENCE:2
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        old = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
SEQUENCE:1
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        expected = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
SEQUENCE:2
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        process(itip, old, expected)
      end

      def test_cancel
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:CANCEL
BEGIN:VEVENT
SEQUENCE:2
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        old = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
SEQUENCE:1
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        expected = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
STATUS:CANCELLED
SEQUENCE:2
END:VEVENT
END:VCALENDAR
ICS

        process(itip, old, expected)
      end

      def test_cancel_no_existing_event
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:CANCEL
BEGIN:VEVENT
SEQUENCE:2
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        old = nil
        expected = nil

        process(itip, old, expected)
      end

      def test_unsupported_component
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
SEQUENCE:2
UID:foobar
END:VTODO
END:VCALENDAR
ICS

        old = nil
        expected = nil

        process(itip, old, expected)
      end

      def test_unsupported_method
        itip = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
BEGIN:VEVENT
SEQUENCE:2
UID:foobar
END:VEVENT
END:VCALENDAR
ICS

        old = nil
        expected = nil

        process(itip, old, expected)
      end
    end
  end
end
