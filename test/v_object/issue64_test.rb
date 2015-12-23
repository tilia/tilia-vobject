require 'test_helper'

module Tilia
  module VObject
    class Issue64Test < Minitest::Test
      def test_read
        vcard = Tilia::VObject::Reader.read(File.read(File.join(File.dirname(__FILE__), 'issue64.vcf')))
        vcard = vcard.convert(Tilia::VObject::Document::VCARD30)
        vcard = vcard.serialize

        converted = Tilia::VObject::Reader.read(vcard)

        assert_kind_of(Tilia::VObject::Component::VCard, converted)
      end
    end
  end
end
