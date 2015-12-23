require 'test_helper'

module Tilia
  module VObject
    class CalAddressTest < Minitest::Test
      def values
        [
          ['mailto:a@b.com', 'mailto:a@b.com'],
          ['mailto:a@b.com', 'MAILTO:a@b.com'],
          ['/foo/bar', '/foo/bar']
        ]
      end

      def test_get_normalized_value
        values.each do |data|
          (expected, input) = data

          vobj = Tilia::VObject::Component::VCalendar.new
          property = vobj.add('ATTENDEE', input)

          assert_equal(expected, property.normalized_value)
        end
      end
    end
  end
end
