require 'test_helper'

module Tilia
  module VObject
    # Assorted vcard 2.1 tests.
    class VCard21Test < Minitest::Test
      def test_property_with_no_name
        input = <<VCF
BEGIN:VCARD\r
VERSION:2.1\r
EMAIL;HOME;WORK:evert@fruux.com\r
END:VCARD\r
VCF

        vobj = Tilia::VObject::Reader.read(input)
        output = vobj.serialize

        assert_equal(input, output)
      end

      def test_property_pad_value_count
        input = <<VCF
BEGIN:VCARD
VERSION:2.1
N:Foo
END:VCARD
VCF

        vobj = Tilia::VObject::Reader.read(input)
        output = vobj.serialize

        expected = <<VCF
BEGIN:VCARD\r
VERSION:2.1\r
N:Foo;;;;\r
END:VCARD\r
VCF

        assert_equal(expected, output)
      end
    end
  end
end
