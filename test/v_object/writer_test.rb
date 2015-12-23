require 'test_helper'

module Tilia
  module VObject
    class WriterTest < Minitest::Test
      def setup
        data = "BEGIN:VCALENDAR\r\nEND:VCALENDAR"
        @component = Tilia::VObject::Reader.read(data)
      end

      def test_write_to_mime_dir
        result = Tilia::VObject::Writer.write(@component)
        assert_equal("BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n", result)
      end

      def test_write_to_json
        result = Tilia::VObject::Writer.write_json(@component)
        assert_equal('["vcalendar",[],[]]', result)
      end

      def test_write_to_xml
        result = Tilia::VObject::Writer.write_xml(@component)
        expected = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
 <vcalendar/>
</icalendar>
XML
        assert_equal(expected, result)
      end
    end
  end
end
