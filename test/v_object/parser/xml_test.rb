require 'test_helper'
require 'v_object/test_case'

module Tilia
  module VObject
    class XmlTest < TestCase
      # Check this equality:
      #     XML -> object model -> MIME Dir.
      def assert_xml_equals_to_mime_dir(xml, mimedir)
        component = Tilia::VObject::Reader.read_xml(xml)
        assert_v_obj_equals(mimedir, component)
      end

      # Check this (reflexive) equality:
      #     XML -> object model -> MIME Dir -> object model -> XML.
      def assert_xml_reflexively_equals_to_mime_dir(xml, mimedir)
        assert_xml_equals_to_mime_dir(xml, mimedir)

        component = Tilia::VObject::Reader.read(mimedir)
        assert_equal(Hash.from_xml(xml), Hash.from_xml(Tilia::VObject::Writer.write_xml(component)))
      end

      def test_rfc6321_example1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <calscale>
     <text>GREGORIAN</text>
   </calscale>
   <prodid>
    <text>-//Example Inc.//Example Calendar//EN</text>
   </prodid>
   <version>
     <text>2.0</text>
   </version>
  </properties>
  <components>
   <vevent>
    <properties>
     <dtstamp>
       <date-time>2008-02-05T19:12:24Z</date-time>
     </dtstamp>
     <dtstart>
       <date>2008-10-06</date>
     </dtstart>
     <summary>
      <text>Planning meeting</text>
     </summary>
     <uid>
      <text>4088E990AD89CB3DBB484909</text>
     </uid>
    </properties>
   </vevent>
  </components>
 </vcalendar>
</icalendar>
XML

        # VERSION comes first because this is required by vCard 4.0.
        vobj = <<VOBJ
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:-//Example Inc.//Example Calendar//EN
BEGIN:VEVENT
DTSTAMP:20080205T191224Z
DTSTART;VALUE=DATE:20081006
SUMMARY:Planning meeting
UID:4088E990AD89CB3DBB484909
END:VEVENT
END:VCALENDAR
VOBJ

        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      def test_rfc6321_example2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8" ?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
  <vcalendar>
    <properties>
      <prodid>
        <text>-//Example Inc.//Example Client//EN</text>
      </prodid>
      <version>
        <text>2.0</text>
      </version>
    </properties>
    <components>
      <vtimezone>
        <properties>
          <last-modified>
            <date-time>2004-01-10T03:28:45Z</date-time>
          </last-modified>
          <tzid><text>US/Eastern</text></tzid>
        </properties>
        <components>
          <daylight>
            <properties>
              <dtstart>
                <date-time>2000-04-04T02:00:00</date-time>
              </dtstart>
              <rrule>
                <recur>
                  <freq>YEARLY</freq>
                  <byday>1SU</byday>
                  <bymonth>4</bymonth>
                </recur>
              </rrule>
              <tzname>
                <text>EDT</text>
              </tzname>
              <tzoffsetfrom>
                <utc-offset>-05:00</utc-offset>
              </tzoffsetfrom>
              <tzoffsetto>
                <utc-offset>-04:00</utc-offset>
              </tzoffsetto>
            </properties>
          </daylight>
          <standard>
            <properties>
              <dtstart>
                <date-time>2000-10-26T02:00:00</date-time>
              </dtstart>
              <rrule>
                <recur>
                  <freq>YEARLY</freq>
                  <byday>-1SU</byday>
                  <bymonth>10</bymonth>
                </recur>
              </rrule>
              <tzname>
                <text>EST</text>
              </tzname>
              <tzoffsetfrom>
                <utc-offset>-04:00</utc-offset>
              </tzoffsetfrom>
              <tzoffsetto>
                <utc-offset>-05:00</utc-offset>
              </tzoffsetto>
            </properties>
          </standard>
        </components>
      </vtimezone>
      <vevent>
        <properties>
          <dtstamp>
            <date-time>2006-02-06T00:11:21Z</date-time>
          </dtstamp>
          <dtstart>
            <parameters>
              <tzid><text>US/Eastern</text></tzid>
            </parameters>
            <date-time>2006-01-02T12:00:00</date-time>
          </dtstart>
          <duration>
            <duration>PT1H</duration>
          </duration>
          <rrule>
            <recur>
              <freq>DAILY</freq>
              <count>5</count>
            </recur>
          </rrule>
          <rdate>
            <parameters>
              <tzid><text>US/Eastern</text></tzid>
            </parameters>
            <period>
              <start>2006-01-02T15:00:00</start>
              <duration>PT2H</duration>
            </period>
          </rdate>
          <summary>
            <text>Event #2</text>
          </summary>
          <description>
            <text>We are having a meeting all this week at 12
pm for one hour, with an additional meeting on the first day
2 hours long.&#x0a;Please bring your own lunch for the 12 pm
meetings.</text>
          </description>
          <uid>
            <text>00959BC664CA650E933C892C@example.com</text>
          </uid>
        </properties>
      </vevent>
      <vevent>
        <properties>
          <dtstamp>
            <date-time>2006-02-06T00:11:21Z</date-time>
          </dtstamp>
          <dtstart>
            <parameters>
              <tzid><text>US/Eastern</text></tzid>
            </parameters>
            <date-time>2006-01-04T14:00:00</date-time>
          </dtstart>
          <duration>
            <duration>PT1H</duration>
          </duration>
          <recurrence-id>
            <parameters>
              <tzid><text>US/Eastern</text></tzid>
            </parameters>
            <date-time>2006-01-04T12:00:00</date-time>
          </recurrence-id>
          <summary>
            <text>Event #2 bis</text>
          </summary>
          <uid>
            <text>00959BC664CA650E933C892C@example.com</text>
          </uid>
        </properties>
      </vevent>
    </components>
  </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Example Inc.//Example Client//EN
BEGIN:VTIMEZONE
LAST-MODIFIED:20040110T032845Z
TZID:US/Eastern
BEGIN:DAYLIGHT
DTSTART:20000404T020000
RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4
TZNAME:EDT
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
END:DAYLIGHT
BEGIN:STANDARD
DTSTART:20001026T020000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
TZNAME:EST
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:20060206T001121Z
DTSTART;TZID=US/Eastern:20060102T120000
DURATION:PT1H
RRULE:FREQ=DAILY;COUNT=5
RDATE;TZID=US/Eastern;VALUE=PERIOD:20060102T150000/PT2H
SUMMARY:Event #2
DESCRIPTION:We are having a meeting all this week at 12\\npm for one hour\\,
 with an additional meeting on the first day\\n2 hours long.\\nPlease bring y
 our own lunch for the 12 pm\\nmeetings.
UID:00959BC664CA650E933C892C@example.com
END:VEVENT
BEGIN:VEVENT
DTSTAMP:20060206T001121Z
DTSTART;TZID=US/Eastern:20060104T140000
DURATION:PT1H
RECURRENCE-ID;TZID=US/Eastern:20060104T120000
SUMMARY:Event #2 bis
UID:00959BC664CA650E933C892C@example.com
END:VEVENT
END:VCALENDAR
VOBJ
        vobj.gsub!('hour\\,', 'hour\\, ') # there was a space at EOL the editor always ate

        component = Tilia::VObject::Reader.read_xml(xml)
        assert_v_obj_equals(vobj, Tilia::VObject::Writer.write(component))
      end

      # iCalendar Stream.
      def test_rfc6321_section3_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar/>
</icalendar>
XML

        vobj = <<VOBJ
BEGIN:VCALENDAR
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # All components exist.
      def test_rfc6321_section3_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <components>
   <vtimezone/>
   <vevent/>
   <vtodo/>
   <vjournal/>
   <vfreebusy/>
   <standard/>
   <daylight/>
   <valarm/>
  </components>
 </vcalendar>
</icalendar>
XML

        vobj = <<VOBJ
BEGIN:VCALENDAR
BEGIN:VTIMEZONE
END:VTIMEZONE
BEGIN:VEVENT
END:VEVENT
BEGIN:VTODO
END:VTODO
BEGIN:VJOURNAL
END:VJOURNAL
BEGIN:VFREEBUSY
END:VFREEBUSY
BEGIN:STANDARD
END:STANDARD
BEGIN:DAYLIGHT
END:DAYLIGHT
BEGIN:VALARM
END:VALARM
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Properties, Special Cases, GEO.
      def test_rfc6321_section3_4_1_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <geo>
    <latitude>37.386013</latitude>
    <longitude>-122.082932</longitude>
   </geo>
  </properties>
 </vcalendar>
</icalendar>
XML

        vobj = <<VOBJ
BEGIN:VCALENDAR
GEO:37.386013;-122.082932
END:VCALENDAR
VOBJ

        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Properties, Special Cases, REQUEST-STATUS.
      def test_rfc6321_section3_4_1_3
        # Example 1 of RFC5545, Section 3.8.8.3.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <request-status>
    <code>2.0</code>
    <description>Success</description>
   </request-status>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
REQUEST-STATUS:2.0;Success
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        # Example 2 of RFC5545, Section 3.8.8.3.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <request-status>
    <code>3.1</code>
    <description>Invalid property value</description>
    <data>DTSTART:96-Apr-01</data>
   </request-status>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
REQUEST-STATUS:3.1;Invalid property value;DTSTART:96-Apr-01
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        # Example 3 of RFC5545, Section 3.8.8.3.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <request-status>
    <code>2.8</code>
    <description>Success, repeating event ignored. Scheduled as a single event.</description>
    <data>RRULE:FREQ=WEEKLY;INTERVAL=2</data>
   </request-status>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
REQUEST-STATUS:2.8;Success\\, repeating event ignored. Scheduled as a single
  event.;RRULE:FREQ=WEEKLY\\;INTERVAL=2
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        # Example 4 of RFC5545, Section 3.8.8.3.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <request-status>
    <code>4.1</code>
    <description>Event conflict.  Date-time is busy.</description>
   </request-status>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
REQUEST-STATUS:4.1;Event conflict.  Date-time is busy.
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        # Example 5 of RFC5545, Section 3.8.8.3.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <request-status>
    <code>3.7</code>
    <description>Invalid calendar user</description>
    <data>ATTENDEE:mailto:jsmith@example.com</data>
   </request-status>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
REQUEST-STATUS:3.7;Invalid calendar user;ATTENDEE:mailto:jsmith@example.com
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Binary.
      def test_rfc6321_section3_6_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <attach>
    <binary>SGVsbG8gV29ybGQh</binary>
   </attach>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
ATTACH:SGVsbG8gV29ybGQh
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        # In vCard 4, BINARY no longer exists and is replaced by URI.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <attach>
    <uri>SGVsbG8gV29ybGQh</uri>
   </attach>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
ATTACH:SGVsbG8gV29ybGQh
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Boolean.
      def test_rfc6321_section3_6_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <attendee>
    <parameters>
     <rsvp><boolean>true</boolean></rsvp>
    </parameters>
    <cal-address>mailto:cyrus@example.com</cal-address>
   </attendee>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
ATTENDEE;RSVP=true:mailto:cyrus@example.com
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      # Values, Calendar User Address.
      def test_rfc6321_section3_6_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <attendee>
    <cal-address>mailto:cyrus@example.com</cal-address>
   </attendee>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
ATTENDEE:mailto:cyrus@example.com
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Date.
      def test_rfc6321_section3_6_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <dtstart>
    <date>2011-05-17</date>
   </dtstart>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
DTSTART;VALUE=DATE:20110517
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Date-Time.
      def test_rfc6321_section3_6_5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <dtstart>
    <date-time>2011-05-17T12:00:00</date-time>
   </dtstart>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
DTSTART:20110517T120000
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Duration.
      def test_rfc6321_section3_6_6
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <duration>
    <duration>P1D</duration>
   </duration>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
DURATION:P1D
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Float.
      def test_rfc6321_section3_6_7
        # GEO uses <float /> with a positive and a non-negative numbers.
        test_rfc6321_section3_4_1_2
      end

      # Values, Integer.
      def test_rfc6321_section3_6_8
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <foo>
    <integer>42</integer>
   </foo>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
FOO:42
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <foo>
    <integer>-42</integer>
   </foo>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
FOO:-42
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      # Values, Period of Time.
      def test_rfc6321_section3_6_9
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <freebusy>
    <period>
     <start>2011-05-17T12:00:00</start>
     <duration>P1H</duration>
    </period>
   </freebusy>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
FREEBUSY:20110517T120000/P1H
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <freebusy>
    <period>
     <start>2011-05-17T12:00:00</start>
     <end>2012-05-17T12:00:00</end>
    </period>
   </freebusy>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
FREEBUSY:20110517T120000/20120517T120000
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Recurrence Rule.
      def test_rfc6321_section3_6_10
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rrule>
    <recur>
     <freq>YEARLY</freq>
     <count>5</count>
     <byday>-1SU</byday>
     <bymonth>10</bymonth>
    </recur>
   </rrule>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RRULE:FREQ=YEARLY;COUNT=5;BYDAY=-1SU;BYMONTH=10
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Text.
      def test_rfc6321_section3_6_11
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <calscale>
    <text>GREGORIAN</text>
   </calscale>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, Time.
      def test_rfc6321_section3_6_12
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <foo>
    <time>12:00:00</time>
   </foo>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
FOO:120000
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      # Values, URI.
      def test_rfc6321_section3_6_13
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <attach>
    <uri>http://calendar.example.com</uri>
   </attach>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
ATTACH:http://calendar.example.com
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Values, UTC Offset.
      def test_rfc6321_section3_6_14
        # Example 1 of RFC5545, Section 3.3.14.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <tzoffsetfrom>
    <utc-offset>-05:00</utc-offset>
   </tzoffsetfrom>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
TZOFFSETFROM:-0500
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        # Example 2 of RFC5545, Section 3.3.14.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <tzoffsetfrom>
    <utc-offset>+01:00</utc-offset>
   </tzoffsetfrom>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
TZOFFSETFROM:+0100
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Handling Unrecognized Properties or Parameters.
      def test_rfc6321_section5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <x-property>
    <unknown>20110512T120000Z</unknown>
   </x-property>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
X-PROPERTY:20110512T120000Z
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <dtstart>
    <parameters>
     <x-param>
      <text>PT30M</text>
     </x-param>
    </parameters>
    <date-time>2011-05-12T13:00:00Z</date-time>
   </dtstart>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
DTSTART;X-PARAM=PT30M:20110512T130000Z
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      def test_r_date_with_date_time
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <date-time>2008-02-05T19:12:24Z</date-time>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE:20080205T191224Z
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <date-time>2008-02-05T19:12:24Z</date-time>
    <date-time>2009-02-05T19:12:24Z</date-time>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE:20080205T191224Z,20090205T191224Z
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      def test_r_date_with_date
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <date>2008-10-06</date>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE:20081006
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <date>2008-10-06</date>
    <date>2009-10-06</date>
    <date>2010-10-06</date>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE:20081006,20091006,20101006
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      def test_r_date_with_period
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <parameters>
     <tzid>
      <text>US/Eastern</text>
     </tzid>
    </parameters>
    <period>
     <start>2006-01-02T15:00:00</start>
     <duration>PT2H</duration>
    </period>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE;TZID=US/Eastern;VALUE=PERIOD:20060102T150000/PT2H
END:VCALENDAR
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
  <properties>
   <rdate>
    <parameters>
     <tzid>
      <text>US/Eastern</text>
     </tzid>
    </parameters>
    <period>
     <start>2006-01-02T15:00:00</start>
     <duration>PT2H</duration>
    </period>
    <period>
     <start>2008-01-02T15:00:00</start>
     <duration>PT1H</duration>
    </period>
   </rdate>
  </properties>
 </vcalendar>
</icalendar>
XML
        vobj = <<VOBJ
BEGIN:VCALENDAR
RDATE;TZID=US/Eastern;VALUE=PERIOD:20060102T150000/PT2H,20080102T150000/PT1
 H
END:VCALENDAR
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      # Basic example.
      def test_rfc6351_basic
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <fn>
   <text>J. Doe</text>
  </fn>
  <n>
   <surname>Doe</surname>
   <given>J.</given>
   <additional/>
   <prefix/>
   <suffix/>
  </n>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
FN:J. Doe
N:Doe;J.;;;
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Example 1.
      def test_rfc6351_example1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <fn>
   <text>J. Doe</text>
  </fn>
  <n>
   <surname>Doe</surname>
   <given>J.</given>
   <additional/>
   <prefix/>
   <suffix/>
  </n>
  <x-file>
   <parameters>
    <mediatype>
     <text>image/jpeg</text>
    </mediatype>
   </parameters>
   <unknown>alien.jpg</unknown>
  </x-file>
  <x1:a href="http://www.example.com" xmlns:x1="http://www.w3.org/1999/xhtml">My web page!</x1:a>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
FN:J. Doe
N:Doe;J.;;;
X-FILE;MEDIATYPE=image/jpeg:alien.jpg
XML:<a xmlns="http://www.w3.org/1999/xhtml" href="http://www.example.com">M
 y web page!</a>
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Design Considerations.
      def test_rfc6351_section5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tel>
   <parameters>
    <type>
     <text>voice</text>
     <text>video</text>
    </type>
   </parameters>
   <uri>tel:+1-555-555-555</uri>
  </tel>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TEL;TYPE="voice,video":tel:+1-555-555-555
END:VCARD
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tel>
   <parameters>
    <type>
     <text>voice</text>
     <text>video</text>
    </type>
   </parameters>
   <text>tel:+1-555-555-555</text>
  </tel>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TEL;TYPE="voice,video":tel:+1-555-555-555
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Design Considerations.
      def test_rfc6351_section5_group
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tel>
   <text>tel:+1-555-555-556</text>
  </tel>
  <group name="contact">
   <tel>
    <text>tel:+1-555-555-555</text>
   </tel>
   <fn>
    <text>Gordon</text>
   </fn>
  </group>
  <group name="media">
   <fn>
    <text>Gordon</text>
   </fn>
  </group>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TEL:tel:+1-555-555-556
contact.TEL:tel:+1-555-555-555
contact.FN:Gordon
media.FN:Gordon
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Extensibility.
      def test_rfc6351_section5_1_no_namespace
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <x-my-prop>
   <parameters>
    <pref>
     <integer>1</integer>
    </pref>
   </parameters>
   <text>value goes here</text>
  </x-my-prop>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
X-MY-PROP;PREF=1:value goes here
END:VCARD
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.1 of Relax NG Schema: value-date.
      def test_rfc6351_value_date_with_year_month_day
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>20150128</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:20150128
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.1 of Relax NG Schema: value-date.
      def test_rfc6351_value_date_with_year_month
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>2015-01</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:2015-01
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.1 of Relax NG Schema: value-date.
      def test_rfc6351_value_date_with_month
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>--01</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:--01
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.1 of Relax NG Schema: value-date.
      def test_rfc6351_value_date_with_month_day
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>--0128</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:--0128
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.1 of Relax NG Schema: value-date.
      def test_rfc6351_value_date_with_day
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_hour
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>13</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:13
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_hour_minute
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>1353</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:1353
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_hour_minute_second
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>135301</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:135301
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_minute
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>-53</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:-53
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_minute_second
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>-5301</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:-5301
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_second
        assert(true)

        # According to the Relax NG Schema, there is a conflict between
        # value-date and value-time. The --01 syntax can only match a
        # value-date because of the higher priority set in
        # value-date-and-or-time. So we basically skip this test.
        #
        #       xml = <<XML
        # <?xml version="1.0" encoding="UTF-8"?>
        # <vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
        #  <vcard>
        #   <bday>
        #    <date-and-or-time>--01</date-and-or-time>
        #   </bday>
        #  </vcard>
        # </vcards>
        # XML
        #       vobj = <<VOBJ
        # BEGIN:VCARD
        # VERSION:4.0
        # BDAY:--01
        # END:VCARD
        # VOBJ
        #       assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_second_z
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>--01Z</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:--01Z
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.2 of Relax NG Schema: value-time.
      def test_rfc6351_value_time_with_second_tz
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>--01+1234</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:--01+1234
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_year_month_day_hour
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>20150128T13</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:20150128T13
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_month_day_hour
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>--0128T13</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:--0128T13
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_day_hour
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28T13</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28T13
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_day_hour_minute
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28T1353</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28T1353
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_day_hour_minute_second
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28T135301</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28T135301
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_day_hour_z
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28T13Z</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28T13Z
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Section 4.3.3 of Relax NG Schema: value-date-time.
      def test_rfc6351_value_date_time_with_day_hour_tz
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>---28T13+1234</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:---28T13+1234
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: SOURCE.
      def test_rfc6350_section6_1_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <source>
   <uri>ldap://ldap.example.com/cn=Babs%20Jensen,%20o=Babsco,%20c=US</uri>
  </source>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
SOURCE:ldap://ldap.example.com/cn=Babs%20Jensen\\,%20o=Babsco\\,%20c=US
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: KIND.
      def test_rfc6350_section6_1_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <kind>
   <text>individual</text>
  </kind>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
KIND:individual
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: FN.
      def test_rfc6350_section6_2_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <fn>
   <text>Mr. John Q. Public, Esq.</text>
  </fn>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
FN:Mr. John Q. Public\\, Esq.
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: N.
      def test_rfc6350_section6_2_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <n>
   <surname>Stevenson</surname>
   <given>John</given>
   <additional>Philip,Paul</additional>
   <prefix>Dr.</prefix>
   <suffix>Jr.,M.D.,A.C.P.</suffix>
  </n>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
N:Stevenson;John;Philip\\,Paul;Dr.;Jr.\\,M.D.\\,A.C.P.
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: NICKNAME.
      def test_rfc6350_section6_2_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <nickname>
   <text>Jim</text>
   <text>Jimmie</text>
  </nickname>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
NICKNAME:Jim,Jimmie
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: PHOTO.
      def test_rfc6350_section6_2_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <photo>
   <uri>http://www.example.com/pub/photos/jqpublic.gif</uri>
  </photo>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
PHOTO:http://www.example.com/pub/photos/jqpublic.gif
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      def test_rfc6350_section6_2_5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <bday>
   <date-and-or-time>19531015T231000Z</date-and-or-time>
  </bday>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
BDAY:19531015T231000Z
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      def test_rfc6350_section6_2_6
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <anniversary>
   <date-and-or-time>19960415</date-and-or-time>
  </anniversary>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
ANNIVERSARY:19960415
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: GENDER.
      def test_rfc6350_section6_2_7
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <gender>
   <sex>Jim</sex>
   <text>Jimmie</text>
  </gender>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
GENDER:Jim;Jimmie
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: ADR.
      def test_rfc6350_section6_3_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <adr>
   <pobox/>
   <ext/>
   <street>123 Main Street</street>
   <locality>Any Town</locality>
   <region>CA</region>
   <code>91921-1234</code>
   <country>U.S.A.</country>
  </adr>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
ADR:;;123 Main Street;Any Town;CA;91921-1234;U.S.A.
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: TEL.
      def test_rfc6350_section6_4_1
        # Quoting RFC:
        # > Value type:  By default, it is a single free-form text value (for
        # > backward compatibility with vCard 3), but it SHOULD be reset to a
        # > URI value.  It is expected that the URI scheme will be "tel", as
        # > specified in [RFC3966], but other schemes MAY be used.
        #
        # So first, we test xCard/URI to vCard/URI.
        # Then, we test xCard/TEXT to vCard/TEXT to xCard/TEXT.
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tel>
   <parameters>
    <type>
     <text>home</text>
    </type>
   </parameters>
   <uri>tel:+33-01-23-45-67</uri>
  </tel>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TEL;TYPE=home:tel:+33-01-23-45-67
END:VCARD
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tel>
   <parameters>
    <type>
     <text>home</text>
    </type>
   </parameters>
   <text>tel:+33-01-23-45-67</text>
  </tel>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TEL;TYPE=home:tel:+33-01-23-45-67
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: EMAIL.
      def test_rfc6350_section6_4_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <email>
   <parameters>
    <type>
     <text>work</text>
    </type>
   </parameters>
   <text>jqpublic@xyz.example.com</text>
  </email>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
EMAIL;TYPE=work:jqpublic@xyz.example.com
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: IMPP.
      def test_rfc6350_section6_4_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <impp>
   <parameters>
    <pref>
     <text>1</text>
    </pref>
   </parameters>
   <uri>xmpp:alice@example.com</uri>
  </impp>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
IMPP;PREF=1:xmpp:alice@example.com
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: LANG.
      def test_rfc6350_section6_4_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <lang>
   <parameters>
    <type>
     <text>work</text>
    </type>
    <pref>
     <text>2</text>
    </pref>
   </parameters>
   <language-tag>en</language-tag>
  </lang>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
LANG;TYPE=work;PREF=2:en
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: TZ.
      def test_rfc6350_section6_5_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <tz>
   <text>Raleigh/North America</text>
  </tz>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TZ:Raleigh/North America
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: GEO.
      def test_rfc6350_section6_5_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <geo>
   <uri>geo:37.386013,-122.082932</uri>
  </geo>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
GEO:geo:37.386013\\,-122.082932
END:VCARD
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <geo>
   <text>geo:37.386013,-122.082932</text>
  </geo>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
GEO:geo:37.386013\\,-122.082932
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: TITLE.
      def test_rfc6350_section6_6_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <title>
   <text>Research Scientist</text>
  </title>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
TITLE:Research Scientist
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: ROLE.
      def test_rfc6350_section6_6_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <role>
   <text>Project Leader</text>
  </role>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
ROLE:Project Leader
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: LOGO.
      def test_rfc6350_section6_6_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <logo>
   <uri>http://www.example.com/pub/logos/abccorp.jpg</uri>
  </logo>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
LOGO:http://www.example.com/pub/logos/abccorp.jpg
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: ORG.
      def test_rfc6350_section6_6_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <org>
   <text>ABC, Inc.</text>
   <text>North American Division</text>
   <text>Marketing</text>
  </org>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
ORG:ABC\, Inc.;North American Division;Marketing
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: MEMBER.
      def test_rfc6350_section6_6_5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <member>
   <uri>urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af</uri>
  </member>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
MEMBER:urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <member>
   <uri>mailto:subscriber1@example.com</uri>
  </member>
  <member>
   <uri>xmpp:subscriber2@example.com</uri>
  </member>
  <member>
   <uri>sip:subscriber3@example.com</uri>
  </member>
  <member>
   <uri>tel:+1-418-555-5555</uri>
  </member>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
MEMBER:mailto:subscriber1@example.com
MEMBER:xmpp:subscriber2@example.com
MEMBER:sip:subscriber3@example.com
MEMBER:tel:+1-418-555-5555
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: RELATED.
      def test_rfc6350_section6_6_6
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <related>
   <parameters>
    <type>
     <text>friend</text>
    </type>
   </parameters>
   <uri>urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6</uri>
  </related>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
RELATED;TYPE=friend:urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: CATEGORIES.
      def test_rfc6350_section6_7_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <categories>
   <text>INTERNET</text>
   <text>IETF</text>
   <text>INDUSTRY</text>
   <text>INFORMATION TECHNOLOGY</text>
  </categories>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
CATEGORIES:INTERNET,IETF,INDUSTRY,INFORMATION TECHNOLOGY
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: NOTE.
      def test_rfc6350_section6_7_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <note>
   <text>Foo, bar</text>
  </note>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
NOTE:Foo\\, bar
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: PRODID.
      def test_rfc6350_section6_7_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <prodid>
   <text>-//ONLINE DIRECTORY//NONSGML Version 1//EN</text>
  </prodid>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
PRODID:-//ONLINE DIRECTORY//NONSGML Version 1//EN
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      def test_rfc6350_section6_7_4
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <rev>
   <timestamp>19951031T222710Z</timestamp>
  </rev>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
REV:19951031T222710Z
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: SOUND.
      def test_rfc6350_section6_7_5
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <sound>
   <uri>CID:JOHNQPUBLIC.part8.19960229T080000.xyzMail@example.com</uri>
  </sound>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
SOUND:CID:JOHNQPUBLIC.part8.19960229T080000.xyzMail@example.com
END:VCARD
VOBJ
        assert_xml_equals_to_mime_dir(xml, vobj)

        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <sound>
   <text>CID:JOHNQPUBLIC.part8.19960229T080000.xyzMail@example.com</text>
  </sound>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
SOUND:CID:JOHNQPUBLIC.part8.19960229T080000.xyzMail@example.com
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: UID.
      def test_rfc6350_section6_7_6
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <uid>
   <text>urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6</text>
  </uid>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
UID:urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: CLIENTPIDMAP.
      def test_rfc6350_section6_7_7
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <clientpidmap>
   <sourceid>1</sourceid>
   <uri>urn:uuid:3df403f4-5924-4bb7-b077-3c711d9eb34b</uri>
  </clientpidmap>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
CLIENTPIDMAP:1;urn:uuid:3df403f4-5924-4bb7-b077-3c711d9eb34b
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: URL.
      def test_rfc6350_section6_7_8
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <url>
   <uri>http://example.org/restaurant.french/~chezchic.html</uri>
  </url>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
URL:http://example.org/restaurant.french/~chezchic.html
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: VERSION.
      def test_rfc6350_section6_7_9
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard/>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: KEY.
      def test_rfc6350_section6_8_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <key>
   <parameters>
    <mediatype>
     <text>application/pgp-keys</text>
    </mediatype>
   </parameters>
   <text>ftp://example.com/keys/jdoe</text>
  </key>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
KEY;MEDIATYPE=application/pgp-keys:ftp://example.com/keys/jdoe
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: FBURL.
      def test_rfc6350_section6_9_1
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <fburl>
   <parameters>
    <pref>
     <text>1</text>
    </pref>
   </parameters>
   <uri>http://www.example.com/busy/janedoe</uri>
  </fburl>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
FBURL;PREF=1:http://www.example.com/busy/janedoe
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: CALADRURI.
      def test_rfc6350_section6_9_2
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <caladruri>
   <uri>http://example.com/calendar/jdoe</uri>
  </caladruri>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
CALADRURI:http://example.com/calendar/jdoe
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: CALURI.
      def test_rfc6350_section6_9_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <caluri>
   <parameters>
    <pref>
     <text>1</text>
    </pref>
   </parameters>
   <uri>http://cal.example.com/calA</uri>
  </caluri>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
CALURI;PREF=1:http://cal.example.com/calA
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end

      # Property: CAPURI.
      def test_rfc6350_section_a_3
        xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<vcards xmlns="urn:ietf:params:xml:ns:vcard-4.0">
 <vcard>
  <capuri>
   <uri>http://cap.example.com/capA</uri>
  </capuri>
 </vcard>
</vcards>
XML
        vobj = <<VOBJ
BEGIN:VCARD
VERSION:4.0
CAPURI:http://cap.example.com/capA
END:VCARD
VOBJ
        assert_xml_reflexively_equals_to_mime_dir(xml, vobj)
      end
    end
  end
end
