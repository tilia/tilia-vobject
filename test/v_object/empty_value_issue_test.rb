require 'test_helper'

module Tilia
  module VObject
    # This test is written for Issue 68:
    #
    # https://github.com/fruux/sabre-vobject/issues/68
    class EmptyValueIssueTest < Minitest::Test
      def test_decode_value
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
DESCRIPTION:This is a descpription\\nwith a linebreak and a \\; \\, and :
END:VEVENT
END:VCALENDAR
ICS
        vobj = Tilia::VObject::Reader.read(input)

        # Before this bug was fixed, self.value would return nothing.
        assert_equal("This is a descpription\nwith a linebreak and a ; , and :", vobj['VEVENT']['DESCRIPTION'].value)
      end
    end
  end
end
