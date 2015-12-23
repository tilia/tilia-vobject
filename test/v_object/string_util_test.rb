require 'test_helper'

module Tilia
  module VObject
    class StringUtilTest < Minitest::Test
      def test_non_utf8
        string = Tilia::VObject::StringUtil.utf8?((0xbf).chr)
        refute(string)
      end

      def test_is_utf8
        string = Tilia::VObject::StringUtil.utf8?('I 💚 SabreDAV')
        assert(string)
      end

      def test_utf8_control_char
        string = Tilia::VObject::StringUtil.utf8?((0x00).chr)
        refute(string)
      end

      def test_convert_to_utf8non_utf8
        string = Tilia::VObject::StringUtil.convert_to_utf8("asdf\xbf")
        assert_equal('asdf¿', string)
      end

      def test_convert_to_utf8_is_utf8
        string = Tilia::VObject::StringUtil.convert_to_utf8('I 💚 SabreDAV')
        assert_equal('I 💚 SabreDAV', string)
      end

      def test_convert_to_utf8_control_char
        string = Tilia::VObject::StringUtil.convert_to_utf8((0x00).chr)
        assert_equal('', string)
      end
    end
  end
end
