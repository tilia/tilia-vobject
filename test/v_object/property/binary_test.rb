require 'test_helper'

module Tilia
  module VObject
    class BinaryTest < Minitest::Test
      def test_mime_dir
        vcard = Tilia::VObject::Component::VCard.new
        assert_raises(ArgumentError) { vcard.add('PHOTO', ['a', 'b']) }
      end
    end
  end
end
