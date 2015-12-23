require 'test_helper'

module Tilia
  module VObject
    class FloatTest < Minitest::Test
      def test_mime_dir
        input = "BEGIN:VCARD\r\nVERSION:4.0\r\nX-FLOAT;VALUE=FLOAT:0.234;1.245\r\nEND:VCARD\r\n"
        mime_dir = Tilia::VObject::Parser::MimeDir.new(input)

        result = mime_dir.parse(input)

        assert_kind_of(Tilia::VObject::Property::FloatValue, result['X-FLOAT'])

        assert_equal([0.234, 1.245], result['X-FLOAT'].parts)

        assert_equal(input, result.serialize)
      end
    end
  end
end
