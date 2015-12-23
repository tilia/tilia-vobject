require 'test_helper'
require 'stringio'

module Tilia
  module VObject
    class ReaderTest < Minitest::Test
      def test_read_component
        data = "BEGIN:VCALENDAR\r\nEND:VCALENDAR"

        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_stream
        data = "BEGIN:VCALENDAR\r\nEND:VCALENDAR"

        stream = StringIO.new
        stream.write(data)
        stream.rewind

        result = Tilia::VObject::Reader.read(stream)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_component_unix_new_line
        data = "BEGIN:VCALENDAR\nEND:VCALENDAR"

        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_component_line_fold
        data = "BEGIN:\r\n\tVCALENDAR\r\nE\r\n ND:VCALENDAR"

        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_corrupt_component
        data = "BEGIN:VCALENDAR\r\nEND:FOO"

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(data) }
      end

      def test_read_corrupt_sub_component
        data = "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nEND:FOO\r\nEND:VCALENDAR"

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(data) }
      end

      def test_read_property
        data = "BEGIN:VCALENDAR\r\nSUMMARY:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['SUMMARY']
        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('SUMMARY', result.name)
        assert_equal('propValue', result.value)
      end

      def test_read_property_with_new_line
        data = "BEGIN:VCALENDAR\r\nSUMMARY:Line1\\nLine2\\NLine3\\\\Not the 4th line!\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['SUMMARY']
        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('SUMMARY', result.name)
        assert_equal("Line1\nLine2\nLine3\\Not the 4th line!", result.value)
      end

      def test_read_mapped_property
        data = "BEGIN:VCALENDAR\r\nDTSTART:20110529\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['DTSTART']
        assert_kind_of(Tilia::VObject::Property::ICalendar::DateTime, result)
        assert_equal('DTSTART', result.name)
        assert_equal('20110529', result.value)
      end

      def test_read_mapped_property_grouped
        data = "BEGIN:VCALENDAR\r\nfoo.DTSTART:20110529\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['DTSTART']
        assert_kind_of(Tilia::VObject::Property::ICalendar::DateTime, result)
        assert_equal('DTSTART', result.name)
        assert_equal('20110529', result.value)
      end

      def test_read_broken_line
        data = "BEGIN:VCALENDAR\r\nPROPNAME;propValue"
        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(data) }
      end

      def test_read_property_in_component
        data = [
          'BEGIN:VCALENDAR',
          'PROPNAME:propValue',
          'END:VCALENDAR'
        ]

        result = Tilia::VObject::Reader.read(data.join("\r\n"))

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(1, result.children.size)
        assert_kind_of(Tilia::VObject::Property, result.children[0])
        assert_equal('PROPNAME', result.children[0].name)
        assert_equal('propValue', result.children[0].value)
      end

      def test_read_nested_component
        data = [
          'BEGIN:VCALENDAR',
          'BEGIN:VTIMEZONE',
          'BEGIN:DAYLIGHT',
          'END:DAYLIGHT',
          'END:VTIMEZONE',
          'END:VCALENDAR'
        ]

        result = Tilia::VObject::Reader.read(data.join("\r\n"))

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(1, result.children.size)
        assert_kind_of(Tilia::VObject::Component, result.children[0])
        assert_equal('VTIMEZONE', result.children[0].name)
        assert_equal(1, result.children[0].children.size)
        assert_kind_of(Tilia::VObject::Component, result.children[0].children[0])
        assert_equal('DAYLIGHT', result.children[0].children[0].name)
      end

      def test_read_property_parameter
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=paramvalue:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal('paramvalue', result.parameters['PARAMNAME'].value)
      end

      def test_read_property_repeating_parameter
        data = "BEGIN:VCALENDAR\r\nPROPNAME;N=1;N=2;N=3,4;N=\"5\",6;N=\"7,8\";N=9,10;N=^'11^':propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('N', result.parameters['N'].name)
        assert_equal('1,2,3,4,5,6,7,8,9,10,"11"', result.parameters['N'].value)
        assert_equal(['1', '2', '3', '4', '5', '6', '7,8', '9', '10', '"11"'], result.parameters['N'].parts)
      end

      def test_read_property_repeating_nameless_guessed_parameter
        data = "BEGIN:VCALENDAR\r\nPROPNAME;WORK;VOICE;PREF:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('TYPE', result.parameters['TYPE'].name)
        assert_equal('WORK,VOICE,PREF', result.parameters['TYPE'].value)
        assert_equal(['WORK', 'VOICE', 'PREF'], result.parameters['TYPE'].parts)
      end

      def test_read_property_no_name
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PRODIGY:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('TYPE', result.parameters['TYPE'].name)
        assert(result.parameters['TYPE'].no_name)
        assert_equal('PRODIGY', result.parameters['TYPE'].to_s)
      end

      def test_read_property_parameter_extra_colon
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=paramvalue:propValue:anotherrandomstring\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue:anotherrandomstring', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal('paramvalue', result.parameters['PARAMNAME'].value)
      end

      def test_read_property2_parameters
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=paramvalue;PARAMNAME2=paramvalue2:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(2, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal('paramvalue', result.parameters['PARAMNAME'].value)
        assert_equal('PARAMNAME2', result.parameters['PARAMNAME2'].name)
        assert_equal('paramvalue2', result.parameters['PARAMNAME2'].value)
      end

      def test_read_property_parameter_quoted
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=\"paramvalue\":propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal('paramvalue', result.parameters['PARAMNAME'].value)
      end

      def test_read_property_parameter_new_lines
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=paramvalue1^nvalue2^^nvalue3:propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)

        assert_equal(1, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal("paramvalue1\nvalue2^nvalue3", result.parameters['PARAMNAME'].value)
      end

      def test_read_property_parameter_quoted_colon
        data = "BEGIN:VCALENDAR\r\nPROPNAME;PARAMNAME=\"param:value\":propValue\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)
        result = result['PROPNAME']

        assert_kind_of(Tilia::VObject::Property, result)
        assert_equal('PROPNAME', result.name)
        assert_equal('propValue', result.value)
        assert_equal(1, result.parameters.size)
        assert_equal('PARAMNAME', result.parameters['PARAMNAME'].name)
        assert_equal('param:value', result.parameters['PARAMNAME'].value)
      end

      def test_read_forgiving
        data = [
          'BEGIN:VCALENDAR',
          'X_PROP:propValue',
          'END:VCALENDAR'
        ]

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(data.join("\r\n")) }

        result = Tilia::VObject::Reader.read(data.join("\r\n"), Tilia::VObject::Reader::OPTION_FORGIVING)

        expected = [
          'BEGIN:VCALENDAR',
          'X_PROP:propValue',
          'END:VCALENDAR',
          ''
        ].join("\r\n")

        assert_equal(expected, result.serialize)
      end

      def test_read_with_invalid_line
        data = [
          'BEGIN:VCALENDAR',
          'DESCRIPTION:propValue',
          "Yes, we've actually seen a file with non-idented property values on multiple lines",
          'END:VCALENDAR'
        ]

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(data.join("\r\n")) }

        result = Tilia::VObject::Reader.read(data.join("\r\n"), Tilia::VObject::Reader::OPTION_IGNORE_INVALID_LINES)

        expected = [
          'BEGIN:VCALENDAR',
          'DESCRIPTION:propValue',
          'END:VCALENDAR',
          ''
        ].join("\r\n")

        assert_equal(expected, result.serialize)
      end

      # Reported as Issue 32.
      def test_read_incomplete_file
        input = <<ICS
BEGIN:VCALENDAR
VERSION:1.0
BEGIN:VEVENT
X-FUNAMBOL-FOLDER:DEFAULT_FOLDER
X-FUNAMBOL-ALLDAY:0
DTSTART:20111017T110000Z
DTEND:20111017T123000Z
X-MICROSOFT-CDO-BUSYSTATUS:BUSY
CATEGORIES:
LOCATION;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:Netviewer Meeting
PRIORITY:1
STATUS:3
X-MICROSOFT-CDO-REPLYTIME:20111017T064200Z
SUMMARY;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:Kopieren: test
CLASS:PUBLIC
AALARM:
RRULE:
X-FUNAMBOL-BILLINGINFO:
X-FUNAMBOL-COMPANIES:
X-FUNAMBOL-MILEAGE:
X-FUNAMBOL-NOAGING:0
ATTENDEE;STATUS=NEEDS ACTION;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:'Heino' heino@test.com
ATTENDEE;STATUS=NEEDS ACTION;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:'Markus' test@test.com
ATTENDEE;STATUS=NEEDS AC
ICS

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(input) }
      end

      def test_read_broken_input
        assert_raises(ArgumentError) { Tilia::VObject::Reader.read(false) }
      end

      def test_read_bom
        data = (0xef).chr + (0xbb).chr + (0xbf).chr + "BEGIN:VCALENDAR\r\nEND:VCALENDAR"
        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_xml_component
        data = <<XML
<?xml version="1.0" encoding="utf-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
 </vcalendar>
</icalendar>
XML

        result = Tilia::VObject::Reader.read_xml(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end

      def test_read_xml_stream
        data = <<XML
<?xml version="1.0" encoding="utf-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar>
 </vcalendar>
</icalendar>
XML

        stream = StringIO.new
        stream.write(data)
        stream.rewind

        result = Tilia::VObject::Reader.read_xml(stream)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCALENDAR', result.name)
        assert_equal(0, result.children.size)
      end
    end
  end
end
