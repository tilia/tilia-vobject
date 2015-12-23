require 'test_helper'
require 'base64'

module Tilia
  module VObject
    class EmptyParameterTest < Minitest::Test
      def test_read
        input = <<VCF
BEGIN:VCARD
VERSION:2.1
N:Doe;Jon;;;
FN:Jon Doe
EMAIL;X-INTERN:foo@example.org
UID:foo
END:VCARD
VCF
        vcard = Tilia::VObject::Reader.read(input)

        assert_kind_of(Tilia::VObject::Component::VCard, vcard)
        vcard = vcard.convert(Tilia::VObject::Document::VCARD30)
        vcard = vcard.serialize

        converted = Tilia::VObject::Reader.read(vcard)
        converted.validate

        assert(converted['EMAIL'].key?('X-INTERN'))

        version = Tilia::VObject::Version::VERSION

        expected = <<VCF
BEGIN:VCARD
VERSION:3.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
N:Doe;Jon;;;
FN:Jon Doe
EMAIL;X-INTERN=:foo@example.org
UID:foo
END:VCARD
VCF

        assert_equal(expected, vcard.delete("\r"))
      end

      def test_v_card21_parameter
        vcard = Tilia::VObject::Component::VCard.new({}, false)
        vcard['VERSION'] = '2.1'
        vcard['PHOTO'] = 'random_stuff'
        vcard['PHOTO'].add(nil, 'BASE64')
        vcard['UID'] = 'foo-bar'

        result = vcard.serialize
        expected = [
          'BEGIN:VCARD',
          'VERSION:2.1',
          'PHOTO;BASE64:' + Base64.strict_encode64('random_stuff'),
          'UID:foo-bar',
          'END:VCARD',
          ''
        ]

        assert_equal(expected.join("\r\n"), result)
      end
    end
  end
end
