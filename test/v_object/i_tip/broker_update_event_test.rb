require 'test_helper'
require 'v_object/i_tip/broker_tester'

module Tilia
  module VObject
    class BrokerUpdateEventTest < ITip::BrokerTester
      def test_invite_change
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'CANCEL',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => true,
            'message'            => <<ICS
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
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:two@example.org',
            'recipient_name'     => 'Two',
            'significant_change' => false,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
ATTENDEE;CN=Three;PARTSTAT=NEEDS-ACTION:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

          },
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:three@example.org',
            'recipient_name'     => 'Three',
            'significant_change' => true,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
ATTENDEE;CN=Three;PARTSTAT=NEEDS-ACTION:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_invite_change_from_non_scheduling_to_scheduling_object
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
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
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_invite_change_from_scheduling_to_non_scheduling_object
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'       => 'foobar',
            'method'    => 'CANCEL',
            'component' => 'VEVENT',
            'message'   => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:CANCEL
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
DTSTART:20140716T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_no_attendees
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        expected = []
        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_remove_instance
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART;TZID=America/Toronto:20140716T120000
RRULE:FREQ=WEEKLY
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART;TZID=America/Toronto:20140716T120000
RRULE:FREQ=WEEKLY
EXDATE;TZID=America/Toronto:20140724T120000
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
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
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
DTSTART;TZID=America/Toronto:20140716T120000
RRULE:FREQ=WEEKLY
EXDATE;TZID=America/Toronto:20140724T120000
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      # This test is identical to the first test, except this time we change the
      # DURATION property.
      #
      # This should ensure that the message is significant for every attendee,
      def test_invite_change_significant_change
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
DURATION:PT1H
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
DURATION:PT2H
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'CANCEL',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => true,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:CANCEL
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
DTSTART:20140716T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:two@example.org',
            'recipient_name'     => 'Two',
            'significant_change' => true,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
DURATION:PT2H
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
ATTENDEE;CN=Three;PARTSTAT=NEEDS-ACTION:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:three@example.org',
            'recipient_name'     => 'Three',
            'significant_change' => true,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
DURATION:PT2H
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
ATTENDEE;CN=Three;PARTSTAT=NEEDS-ACTION:mailto:three@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_invite_no_change
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => false,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_invite_no_change_force_send
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;SCHEDULE-FORCE-SEND=REQUEST;CN=One:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => true,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;PARTSTAT=ACCEPTED:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end

      def test_invite_remove_attendees
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
SUMMARY:foo
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
SEQUENCE:2
SUMMARY:foo
DTSTART:20140716T120000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'CANCEL',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => true,
            'message'            => <<ICS
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
            'uid'                => 'foobar',
            'method'             => 'CANCEL',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:two@example.org',
            'recipient_name'     => 'Two',
            'significant_change' => true,
            'message'            => <<ICS
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

      def test_invite_change_exdate_order
        old_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Apple Inc.//Mac OS X 10.10.1//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:foobar
SEQUENCE:0
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;CUTYPE=INDIVIDUAL;EMAIL=strunk@example.org;PARTSTAT=ACCE
 PTED:mailto:strunk@example.org
ATTENDEE;CN=One;CUTYPE=INDIVIDUAL;EMAIL=one@example.org;PARTSTAT=ACCEPTED;R
 OLE=REQ-PARTICIPANT;SCHEDULE-STATUS="1.2;Message delivered locally":mailto
 :one@example.org
SUMMARY:foo
DTSTART:20141211T160000Z
DTEND:20141211T170000Z
RRULE:FREQ=WEEKLY
EXDATE:20141225T160000Z,20150101T160000Z
EXDATE:20150108T160000Z
END:VEVENT
END:VCALENDAR
ICS

        new_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Apple Inc.//Mac OS X 10.10.1//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;CUTYPE=INDIVIDUAL;EMAIL=strunk@example.org;PARTSTAT=ACCE
 PTED:mailto:strunk@example.org
ATTENDEE;CN=One;CUTYPE=INDIVIDUAL;EMAIL=one@example.org;PARTSTAT=ACCEPTED;R
 OLE=REQ-PARTICIPANT;SCHEDULE-STATUS=1.2:mailto:one@example.org
DTSTART:20141211T160000Z
DTEND:20141211T170000Z
RRULE:FREQ=WEEKLY
EXDATE:20150101T160000Z
EXDATE:20150108T160000Z,20141225T160000Z
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION

        expected = [
          {
            'uid'                => 'foobar',
            'method'             => 'REQUEST',
            'component'          => 'VEVENT',
            'sender'             => 'mailto:strunk@example.org',
            'sender_name'        => 'Strunk',
            'recipient'          => 'mailto:one@example.org',
            'recipient_name'     => 'One',
            'significant_change' => false,
            'message'            => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
SEQUENCE:1
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Strunk;CUTYPE=INDIVIDUAL;EMAIL=strunk@example.org;PARTSTAT=ACCE
 PTED:mailto:strunk@example.org
ATTENDEE;CN=One;CUTYPE=INDIVIDUAL;EMAIL=one@example.org;PARTSTAT=ACCEPTED;R
 OLE=REQ-PARTICIPANT:mailto:one@example.org
DTSTART:20141211T160000Z
DTEND:20141211T170000Z
RRULE:FREQ=WEEKLY
EXDATE:20150101T160000Z
EXDATE:20150108T160000Z,20141225T160000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        parse(old_message, new_message, expected, 'mailto:strunk@example.org')
      end
    end
  end
end
