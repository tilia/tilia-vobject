require 'test_helper'

module Tilia
  module VObject
    class CalAddressTest < Minitest::Test
      def assert_v_card21_serialization(prop_value, expected)
        doc = Tilia::VObject::Component::VCard.new(
          {
            'VERSION' => '2.1',
            'PROP'    => prop_value
          },
          false
        )

        # Adding quoted-printable, because we're testing if it gets removed
        # automatically.
        doc['PROP']['ENCODING'] = 'QUOTED-PRINTABLE'
        doc['PROP']['P1'] = 'V1'

        output = doc.serialize

        assert_equal("BEGIN:VCARD\r\nVERSION:2.1\r\n#{expected}\r\nEND:VCARD\r\n", output)
      end

      def test_serialize_v_card21
        assert_v_card21_serialization(
          'f;oo',
          'PROP;P1=V1:f;oo'
        )
      end

      def test_serialize_v_card21_array
        assert_v_card21_serialization(
          ['f;oo', 'bar'],
          'PROP;P1=V1:f\;oo;bar'
        )
      end

      def test_serialize_v_card21_fold
        assert_v_card21_serialization(
          'x' * 80,
          'PROP;P1=V1:' + ('x' * 64) + "\r\n " + ('x' * 16)
        )
      end

      def test_serialize_quoted_printable
        assert_v_card21_serialization(
          "foo\r\nbar",
          'PROP;P1=V1;ENCODING=QUOTED-PRINTABLE:foo=0D=0Abar'
        )
      end

      def test_serialize_quoted_printable_fold
        assert_v_card21_serialization(
          "foo\r\nbarxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
          "PROP;P1=V1;ENCODING=QUOTED-PRINTABLE:foo=0D=0Abarxxxxxxxxxxxxxxxxxxxxxxxxxx=\r\n xxx"
        )
      end

      def test_validate_minimum_prop_value
        vcard = <<IN
BEGIN:VCARD
VERSION:4.0
UID:foo
FN:Hi!
N:A
END:VCARD
IN

        vcard = Tilia::VObject::Reader.read(vcard)
        assert_equal(1, vcard.validate.size)

        assert_equal(1, vcard['N'].parts.size)

        vcard.validate(Tilia::VObject::Node::REPAIR)

        assert_equal(5, vcard['N'].parts.size)
      end
    end
  end
end
