require 'test_helper'

module Tilia
  module VObject
    class BooleanTest < Minitest::Test
      def test_mime_dir
        input = "BEGIN:VCARD\r\nX-AWESOME;VALUE=BOOLEAN:TRUE\r\nX-SUCKS;VALUE=BOOLEAN:FALSE\r\nEND:VCARD\r\n"

        vcard = Tilia::VObject::Reader.read(input)
        assert(vcard['X-AWESOME'].value)
        refute(vcard['X-SUCKS'].value)

        assert_equal('BOOLEAN', vcard['X-AWESOME'].value_type)
        assert_equal(input, vcard.serialize)
      end
    end
  end
end
