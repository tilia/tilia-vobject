require 'test_helper'

module Tilia
  module VObject
    class LineFoldingIssueTest < Minitest::Test
      def test_read
        event = <<ICS
BEGIN:VCALENDAR\r
BEGIN:VEVENT\r
DESCRIPTION:TEST\\n\\n \\n\\nTEST\\n\\n \\n\\nTEST\\n\\n \\n\\nTEST\\n\\nTEST\\nTEST, TEST\r
END:VEVENT\r
END:VCALENDAR\r
ICS
        obj = Tilia::VObject::Reader.read(event)
        assert_equal(event, obj.serialize)
      end
    end
  end
end
