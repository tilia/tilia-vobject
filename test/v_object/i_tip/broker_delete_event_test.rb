require 'test_helper'
require 'v_object/i_tip/broker_tester'

module Tilia
  module VObject
    class BrokerDeleteEventTest < ITip::BrokerTester
      def test_organizer_delete
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = nil

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'            => 'foobar',
            'method'         => 'CANCEL',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:strunk@example.org',
            'sender_name'    => 'Strunk',
            'recipient'      => 'mailto:one@example.org',
            'recipient_name' => 'One',
            'message'        => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:CANCEL
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
DTSTART:20140716T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'            => 'foobar',
            'method'         => 'CANCEL',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:strunk@example.org',
            'sender_name'    => 'Strunk',
            'recipient'      => 'mailto:two@example.org',
            'recipient_name' => 'Two',
            'message'        => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:CANCEL
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
DTSTART:20140716T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_attendee_delete
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = nil

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'            => 'foobar',
            'method'         => 'REPLY',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:one@example.org',
            'sender_name'    => 'One',
            'recipient'      => 'mailto:strunk@example.org',
            'recipient_name' => 'Strunk',
            'message'        => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REPLY
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
DTSTART:20140716T120000Z
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;PARTSTAT=DECLINED;CN=One:mailto:one@example.org
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:one@example.org')
      end

      def test_attendee_delete_cancelled_event
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
STATUS:CANCELLED
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = nil

        expected = []

        parse(old_message, new_message, expected, 'mailto:one@example.org')
      end

      def test_no_calendar
        parse(nil, nil, [], 'mailto:one@example.org')
      end

      def test_v_todo
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
UID:foobar
SEQUENCE:1
END:VTODO
END:VCALENDAR
ICS
        parse(old_message, nil, [], 'mailto:one@example.org')
      end
    end
  end
end
