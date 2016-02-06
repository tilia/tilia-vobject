require 'test_helper'

module Tilia
  module VObject
    # Note that most MimeDir related tests can actually be found in the ReaderTest
    # class one level up.
    class MimeDirTest < Minitest::Test
      def test_parse_error
        mime_dir = Tilia::VObject::Parser::MimeDir.new
        assert_raises(Tilia::VObject::ParseException) { mime_dir.parse(File.open(__FILE__)) }
      end

      def test_decode_latin1
         vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
FN:umlaut u - \xFC
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        mime_dir.charset = 'ISO-8859-1'
        vcard = mime_dir.parse(vcard)
        assert_equal("umlaut u - \xC3\xBC", vcard['FN'].value)
      end

      def test_decode_inline_latin1
        vcard = <<VCF
BEGIN:VCARD
VERSION:2.1
FN;CHARSET=ISO-8859-1:umlaut u - \xFC
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        vcard = mime_dir.parse(vcard)
        assert_equal("umlaut u - \xC3\xBC", vcard['FN'].value)
      end

      def test_ignore_charset_v_card30
        vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
FN;CHARSET=unknown:foo-bar - \xFC
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        vcard = mime_dir.parse(vcard)

        # encode(u8, u8) is noop but sets encoding to utf-8, that's what the other string is
        assert_equal("foo-bar - \xFC", vcard['FN'].value.encode('UTF-8', 'UTF-8'))
      end

      def test_dont_decode_latin1
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
FN:umlaut u - \xFC
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        vcard = mime_dir.parse(vcard)
        # This basically tests that we don't touch the input string if
        # the encoding was set to UTF-8. The result is actually invalid
        # and the validator should report this, but it tests effectively
        # that we pass through the string byte-by-byte.

        # encode(u8, u8) is noop but sets encoding to utf-8, that's what the other string is
        assert_equal("umlaut u - \xFC", vcard['FN'].value.encode('UTF-8', 'UTF-8'))
      end

      def test_decode_unsupported_charset
        mime_dir = Parser::MimeDir.new
        assert_raises(ArgumentError) do
          mime_dir.charset = 'foobar'
        end
      end

      def test_decode_unsupported_inline_charset
        vcard = <<VCF
BEGIN:VCARD
VERSION:2.1
FN;CHARSET=foobar:nothing
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        assert_raises(ParseException) do
          mime_dir.parse(vcard)
        end
      end

      def test_decode_windows1252
        vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
FN:Euro \x80
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        mime_dir.charset = 'Windows-1252'
        vcard = mime_dir.parse(vcard)
        assert_equal("Euro \xE2\x82\xAC", vcard['FN'].value)
      end

      def test_decode_windows1252_inline
        vcard = <<VCF
BEGIN:VCARD
VERSION:2.1
FN;CHARSET=Windows-1252:Euro \x80
END:VCARD
VCF

        mime_dir = Parser::MimeDir.new
        vcard = mime_dir.parse(vcard)
        assert_equal("Euro \xE2\x82\xAC", vcard['FN'].value)
      end
    end
  end
end
