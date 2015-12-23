require 'test_helper'

module Tilia
  module VObject
    class TimeZoneUtilTest < Minitest::Test
      def setup
        Tilia::VObject::TimeZoneUtil.map = nil
      end

      def mapping
        Tilia::VObject::TimeZoneUtil.load_tz_maps
        Tilia::VObject::TimeZoneUtil.map.map { |i| [i[1]] }
      end

      def test_correct_tz
        mapping.each do |data|
          (timezone_name,) = data
          tz = ActiveSupport::TimeZone.new(timezone_name)
          assert_kind_of(ActiveSupport::TimeZone, tz)
        end
      end

      def test_exchange_map
        vobj = <<HI
BEGIN:VCALENDAR
METHOD:REQUEST
VERSION:2.0
BEGIN:VTIMEZONE
TZID:foo
X-MICROSOFT-CDO-TZID:2
BEGIN:STANDARD
DTSTART:16010101T030000
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=10;BYDAY=-1SU
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:16010101T020000
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:20120416T092149Z
DTSTART;TZID="foo":20120418T1
 00000
SUMMARY:Begin Unterhaltsreinigung
UID:040000008200E00074C5B7101A82E0080000000010DA091DC31BCD01000000000000000
 0100000008FECD2E607780649BE5A4C9EE6418CBC
 000
END:VEVENT
END:VCALENDAR
HI
        tz = Tilia::VObject::TimeZoneUtil.time_zone('foo', Tilia::VObject::Reader.read(vobj))
        ex = ActiveSupport::TimeZone.new('Europe/Lisbon')

        assert_equal(ex.name, tz.name)
      end

      def test_wether_microsoft_is_still_insane
        vobj = <<HI
BEGIN:VCALENDAR
METHOD:REQUEST
VERSION:2.0
BEGIN:VTIMEZONE
TZID:(GMT+01.00) Sarajevo/Warsaw/Zagreb
X-MICROSOFT-CDO-TZID:2
BEGIN:STANDARD
DTSTART:16010101T030000
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
END:VCALENDAR
HI
        tz = Tilia::VObject::TimeZoneUtil.time_zone('(GMT+01.00) Sarajevo/Warsaw/Zagreb', Tilia::VObject::Reader.read(vobj))
        ex = ActiveSupport::TimeZone.new('Europe/Sarajevo')

        assert_equal(ex.name, tz.name)
      end

      def test_unknown_exchange_id
        vobj = <<HI
BEGIN:VCALENDAR
METHOD:REQUEST
VERSION:2.0
BEGIN:VTIMEZONE
TZID:foo
X-MICROSOFT-CDO-TZID:2000
BEGIN:STANDARD
DTSTART:16010101T030000
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=10;BYDAY=-1SU
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:16010101T020000
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:20120416T092149Z
DTSTART;TZID="foo":20120418T1
 00000
SUMMARY:Begin Unterhaltsreinigung
UID:040000008200E00074C5B7101A82E0080000000010DA091DC31BCD01000000000000000
 0100000008FECD2E607780649BE5A4C9EE6418CBC
DTEND;TZID="Sarajevo, Skopje, Sofija, Vilnius, Warsaw, Zagreb":20120418T103
 000
END:VEVENT
END:VCALENDAR
HI
        tz = Tilia::VObject::TimeZoneUtil.time_zone('foo', Tilia::VObject::Reader.read(vobj))
        ex = Time.zone
        assert_equal(ex.name, tz.name)
      end

      def test_windows_time_zone
        tz = Tilia::VObject::TimeZoneUtil.time_zone('Eastern Standard Time')
        ex = ActiveSupport::TimeZone.new('America/New_York')
        assert_equal(ex.name, tz.name)
      end

      # Ignore testTimeZoneIdentifiers and testTimeZoneBCIdentifiers

      def test_timezone_offset
        tz = Tilia::VObject::TimeZoneUtil.time_zone('GMT-0400', nil, true)
        ex = ActiveSupport::TimeZone.new('Etc/GMT-4')

        assert_equal(ex.name, tz.name)
      end

      def test_timezone_fail
        assert_raises(ArgumentError) { Tilia::VObject::TimeZoneUtil.time_zone('FooBar', nil, true) }
      end

      def test_fall_back
        vobj = <<HI
BEGIN:VCALENDAR
METHOD:REQUEST
VERSION:2.0
BEGIN:VTIMEZONE
TZID:foo
BEGIN:STANDARD
DTSTART:16010101T030000
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=10;BYDAY=-1SU
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:16010101T020000
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:20120416T092149Z
DTSTART;TZID="foo":20120418T1
 00000
SUMMARY:Begin Unterhaltsreinigung
UID:040000008200E00074C5B7101A82E0080000000010DA091DC31BCD01000000000000000
 0100000008FECD2E607780649BE5A4C9EE6418CBC
 000
END:VEVENT
END:VCALENDAR
HI

        tz = Tilia::VObject::TimeZoneUtil.time_zone('foo', Tilia::VObject::Reader.read(vobj))
        ex = Time.zone
        assert_equal(ex.name, tz.name)
      end

      def test_ljubljana_bug
        vobj = <<HI
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Ximian//NONSGML Evolution Calendar//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:/freeassociation.sourceforge.net/Tzfile/Europe/Ljubljana
X-LIC-LOCATION:Europe/Ljubljana
BEGIN:STANDARD
TZNAME:CET
DTSTART:19701028T030000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
END:STANDARD
BEGIN:DAYLIGHT
TZNAME:CEST
DTSTART:19700325T020000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
UID:foo
DTSTART;TZID=/freeassociation.sourceforge.net/Tzfile/Europe/Ljubljana:
 20121003T080000
DTEND;TZID=/freeassociation.sourceforge.net/Tzfile/Europe/Ljubljana:
 20121003T083000
TRANSP:OPAQUE
SEQUENCE:2
SUMMARY:testing
CREATED:20121002T172613Z
LAST-MODIFIED:20121002T172613Z
END:VEVENT
END:VCALENDAR

HI

        tz = Tilia::VObject::TimeZoneUtil.time_zone('/freeassociation.sourceforge.net/Tzfile/Europe/Ljubljana', Tilia::VObject::Reader.read(vobj))
        ex = ActiveSupport::TimeZone.new('Europe/Ljubljana')
        assert_equal(ex.name, tz.name)
      end

      def test_weird_system_vli_cs
        vobj = <<HI
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Ximian//NONSGML Evolution Calendar//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:/freeassociation.sourceforge.net/Tzfile/SystemV/EST5EDT
X-LIC-LOCATION:SystemV/EST5EDT
BEGIN:STANDARD
TZNAME:EST
DTSTART:19701104T020000
RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=11
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
END:STANDARD
BEGIN:DAYLIGHT
TZNAME:EDT
DTSTART:19700311T020000
RRULE:FREQ=YEARLY;BYDAY=2SU;BYMONTH=3
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
UID:20121026T021107Z-6301-1000-1-0@chAir
DTSTAMP:20120905T172126Z
DTSTART;TZID=/freeassociation.sourceforge.net/Tzfile/SystemV/EST5EDT:
 20121026T153000
DTEND;TZID=/freeassociation.sourceforge.net/Tzfile/SystemV/EST5EDT:
 20121026T160000
TRANSP:OPAQUE
SEQUENCE:5
SUMMARY:pick up Ibby
CLASS:PUBLIC
CREATED:20121026T021108Z
LAST-MODIFIED:20121026T021118Z
X-EVOLUTION-MOVE-CALENDAR:1
END:VEVENT
END:VCALENDAR
HI

        tz = Tilia::VObject::TimeZoneUtil.time_zone('/freeassociation.sourceforge.net/Tzfile/SystemV/EST5EDT', Tilia::VObject::Reader.read(vobj), true)
        ex = ActiveSupport::TimeZone.new('EST5EDT') # Ruby supports EST5EDT, sabre/php would say America/New_York
        assert_equal(ex.name, tz.name)
      end
    end
  end
end
