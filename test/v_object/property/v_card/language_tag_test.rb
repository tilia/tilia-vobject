require 'test_helper'

module Tilia
  module VObject
    class LanguageTagTest < Minitest::Test
      def test_mime_dir
        input = "BEGIN:VCARD\r\nVERSION:4.0\r\nLANG:nl\r\nEND:VCARD\r\n"
        mime_dir = Tilia::VObject::Parser::MimeDir.new(input)
        result = mime_dir.parse(input)

        assert_kind_of(Tilia::VObject::Property::VCard::LanguageTag, result['LANG'])
        assert_equal('nl', result['LANG'].value)

        assert_equal(input, result.serialize)
      end

      def test_change_and_serialize
        input = "BEGIN:VCARD\r\nVERSION:4.0\r\nLANG:nl\r\nEND:VCARD\r\n"
        mime_dir = Tilia::VObject::Parser::MimeDir.new(input)

        result = mime_dir.parse(input)

        assert_kind_of(Tilia::VObject::Property::VCard::LanguageTag, result['LANG'])
        # This replicates what the vcard converter does and triggered a bug in
        # the past.
        result['LANG'].value = ['de']

        assert_equal('de', result['LANG'].value)

        expected = "BEGIN:VCARD\r\nVERSION:4.0\r\nLANG:de\r\nEND:VCARD\r\n"
        assert_equal(expected, result.serialize)
      end
    end
  end
end
