require 'test_helper'

module Tilia
  module VObject
    class AttachIssueTest < Minitest::Test
      def test_read
        event = <<ICS
BEGIN:VCALENDAR\r
BEGIN:VEVENT\r
ATTACH;FMTTYPE=;ENCODING=:Zm9v\r
END:VEVENT\r
END:VCALENDAR\r
ICS
        obj = Tilia::VObject::Reader.read(event)
        assert_equal(event, obj.serialize)
      end
    end
  end
end
