require 'test_helper'

module Tilia
  module VObject
    class Issue96Test < Minitest::Test
      def test_read
        input = <<VCF
BEGIN:VCARD
VERSION:2.1
SOURCE:Yahoo Contacts (http://contacts.yahoo.com)
URL;CHARSET=utf-8;ENCODING=QUOTED-PRINTABLE:=
http://www.example.org
END:VCARD
VCF

        vcard = Tilia::VObject::Reader.read(input, Tilia::VObject::Reader::OPTION_FORGIVING)
        assert_kind_of(Tilia::VObject::Component::VCard, vcard)
        assert_equal('http://www.example.org', vcard['URL'].value)
      end
    end
  end
end
