require 'test_helper'

module Tilia
  module VObject
    class CompoundTest < Minitest::Test
      def test_set_parts
        arr = [
          'ABC, Inc.',
          'North American Division',
          'Marketing;Sales'
        ]

        vcard = Tilia::VObject::Component::VCard.new
        elem = vcard.create_property('ORG')
        elem.parts = arr

        assert_equal('ABC\, Inc.;North American Division;Marketing\;Sales', elem.value)
        assert_equal(3, elem.parts.size)
        parts = elem.parts
        assert_equal('Marketing;Sales', parts[2])
      end

      def test_get_parts
        str = 'ABC\\, Inc.;North American Division;Marketing\\;Sales'

        vcard = Tilia::VObject::Component::VCard.new
        elem = vcard.create_property('ORG')
        elem.raw_mime_dir_value = str

        assert_equal(3, elem.parts.size)
        parts = elem.parts
        assert_equal('Marketing;Sales', parts[2])
      end

      def test_get_parts_null
        vcard = Tilia::VObject::Component::VCard.new
        elem = vcard.create_property('ORG', nil)

        assert_equal(0, elem.parts.size)
      end
    end
  end
end
