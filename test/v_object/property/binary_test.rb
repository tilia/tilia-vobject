require 'test_helper'

module Tilia
  module VObject
    class BinaryTest < Minitest::Test
      def test_mime_dir
        vcard = Tilia::VObject::Component::VCard.new('VERSION' => '3.0')
        assert_raises(ArgumentError) do
          vcard.add('PHOTO', ['a', 'b'])
        end
      end
    end
  end
end
