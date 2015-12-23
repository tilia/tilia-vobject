require 'test_helper'

module Tilia
  module VObject
    class QuotedPrintableTest < Minitest::Test
      def property_value(property)
        property.to_s
      end

      def test_read_quoted_printable_simple
        data = "BEGIN:VCARD\r\nLABEL;ENCODING=QUOTED-PRINTABLE:Aach=65n\r\nEND:VCARD"

        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCARD', result.name)
        assert_equal(1, result.children.size)
        assert_equal('Aachen', property_value(result['LABEL']))
      end

      def test_read_quoted_printable_newline_soft
        data = "BEGIN:VCARD\r\nLABEL;ENCODING=QUOTED-PRINTABLE:Aa=\r\n ch=\r\n en\r\nEND:VCARD"
        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCARD', result.name)
        assert_equal(1, result.children.size)
        assert_equal('Aachen', property_value(result['LABEL']))
      end

      def test_read_quoted_printable_newline_hard
        data = "BEGIN:VCARD\r\nLABEL;ENCODING=QUOTED-PRINTABLE:Aachen=0D=0A=\r\n Germany\r\nEND:VCARD"
        result = Tilia::VObject::Reader.read(data)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCARD', result.name)
        assert_equal(1, result.children.size)
        assert_equal("Aachen\r\nGermany", property_value(result['LABEL']))
      end

      def test_read_quoted_printable_compatibility_ms
        data = "BEGIN:VCARD\r\nLABEL;ENCODING=QUOTED-PRINTABLE:Aachen=0D=0A=\r\nDeutschland:okay\r\nEND:VCARD"
        result = Tilia::VObject::Reader.read(data, Tilia::VObject::Reader::OPTION_FORGIVING)

        assert_kind_of(Tilia::VObject::Component, result)
        assert_equal('VCARD', result.name)
        assert_equal(1, result.children.size)
        assert_equal("Aachen\r\nDeutschland:okay", property_value(result['LABEL']))
      end

      def test_read_quotes_printable_compound_values
        data = <<VCF
BEGIN:VCARD
VERSION:2.1
N:Doe;John;;
FN:John Doe
ADR;WORK;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:;;M=C3=BCnster =
Str. 1;M=C3=BCnster;;48143;Deutschland
END:VCARD
VCF

        result = Tilia::VObject::Reader.read(data, Tilia::VObject::Reader::OPTION_FORGIVING)
        assert_equal(
          [
            '',
            '',
            'Münster Str. 1',
            'Münster',
            '',
            '48143',
            'Deutschland'
          ],
          result['ADR'].parts
        )
      end
    end
  end
end
