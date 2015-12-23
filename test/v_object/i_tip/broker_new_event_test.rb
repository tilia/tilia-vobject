require 'test_helper'
require 'v_object/i_tip/broker_tester'

module Tilia
  module VObject
    class BrokerNewEventTest < ITip::BrokerTester
      # Similar to the one in broker_helper, but not the same
      def local_parse(message, expected = [])
        parse(nil, message, expected, 'mailto:strunk@example.org')
      end

      def test_no_attendee
        message = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20140811T220000Z
END:VEVENT
END:VCALENDAR
ICS

        local_parse(message)
      end

      def test_vtodo
        message = <<ICS
BEGIN:VCALENDAR
BEGIN:VTODO
UID:foobar
END:VTODO
END:VCALENDAR
ICS

        local_parse(message)
      end

      def test_simple_invite
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
DTSTART:20140811T220000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White:mailto:white@example.org
END:VEVENT
END:VCALENDAR
ICS

        version = Tilia::VObject::Version::VERSION
        expected_message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
DTSTART:20140811T220000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White;PARTSTAT=NEEDS-ACTION:mailto:white@example.org
END:VEVENT
END:VCALENDAR
ICS

        expected = [
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:strunk@example.org',
            'sender_name'    => 'Strunk',
            'recipient'      => 'mailto:white@example.org',
            'recipient_name' => 'White',
            'message'        => expected_message
          }
        ]

        local_parse(message, expected)
      end

      def test_broken_event_uid_mis_match
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White:mailto:white@example.org
END:VEVENT
BEGIN:VEVENT
UID:foobar2
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White:mailto:white@example.org
END:VEVENT
END:VCALENDAR
ICS

        assert_raises(Tilia::VObject::ITip::ITipException) { local_parse(message, []) }
      end

      def test_broken_event_organizer_mis_match
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White:mailto:white@example.org
END:VEVENT
BEGIN:VEVENT
UID:foobar
ORGANIZER:mailto:foo@example.org
ATTENDEE;CN=White:mailto:white@example.org
END:VEVENT
END:VCALENDAR
ICS

        assert_raises(Tilia::VObject::ITip::ITipException) { local_parse(message, []) }
      end

      def test_recurrence_invite
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
EXDATE:20140717T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
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
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
EXDATE:20140717T120000Z,20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
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
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
EXDATE:20140717T120000Z
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:strunk@example.org',
            'sender_name'    => 'Strunk',
            'recipient'      => 'mailto:three@example.org',
            'recipient_name' => 'Three',
            'message'        => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        local_parse(message, expected)
      end

      def test_recurrence_invite2
        # This method tests a nearly identical path, but in this case the
        # master event does not have an EXDATE.
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
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
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
EXDATE:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
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
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One;PARTSTAT=NEEDS-ACTION:mailto:one@example.org
ATTENDEE;CN=Two;PARTSTAT=NEEDS-ACTION:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          },
          {
            'uid'            => 'foobar',
            'method'         => 'REQUEST',
            'component'      => 'VEVENT',
            'sender'         => 'mailto:strunk@example.org',
            'sender_name'    => 'Strunk',
            'recipient'      => 'mailto:three@example.org',
            'recipient_name' => 'Three',
            'message'        => <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS
          }
        ]

        local_parse(message, expected)
      end

      def test_schedule_agent_client
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
DTSTART:20140811T220000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=White;SCHEDULE-AGENT=CLIENT:mailto:white@example.org
END:VEVENT
END:VCALENDAR
ICS

        expected = []
        local_parse(message, expected)
      end

      def test_multiple_uid
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
END:VEVENT
BEGIN:VEVENT
UID:foobar2
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_raises(Tilia::VObject::ITip::ITipException) { local_parse(message, []) }
      end

      def test_changing_organizers
        message = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:foobar
ORGANIZER;CN=Strunk:mailto:strunk@example.org
ATTENDEE;CN=One:mailto:one@example.org
ATTENDEE;CN=Two:mailto:two@example.org
DTSTART:20140716T120000Z
RRULE:FREQ=DAILY
END:VEVENT
BEGIN:VEVENT
UID:foobar
RECURRENCE-ID:20140718T120000Z
ORGANIZER;CN=Strunk:mailto:ew@example.org
ATTENDEE;CN=Two:mailto:two@example.org
ATTENDEE;CN=Three:mailto:three@example.org
DTSTART:20140718T120000Z
END:VEVENT
END:VCALENDAR
ICS

        assert_raises(Tilia::VObject::ITip::SameOrganizerForAllComponentsException) { local_parse(message, []) }
      end

      def test_no_organizer_has_attendee
        message = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:foobar
DTSTART:20140811T220000Z
ATTENDEE;CN=Two:mailto:two@example.org
END:VEVENT
END:VCALENDAR
ICS

        local_parse(message, [])
      end
    end
  end
end
