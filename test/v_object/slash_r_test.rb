require 'test_helper'

module Tilia
  module VObject
    # This issue was pointed out in Issue 55. \r should be stripped completely
    # when encoding property values.
    class SlashRTest < Minitest::Test
      def test_encode
        vcal = Tilia::VObject::Component::VCalendar.new
        prop = vcal.add('test', "abc\r\ndef")
        assert_equal("TEST:abc\\ndef\r\n", prop.serialize)
      end
    end
  end
end
