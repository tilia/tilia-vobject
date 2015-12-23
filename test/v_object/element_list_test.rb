require 'test_helper'

module Tilia
  module VObject
    class ElementListTest < Minitest::Test
      def test_iterate
        cal = Tilia::VObject::Component::VCalendar.new
        sub = cal.create_component('VEVENT')

        elems = [sub, sub.clone, sub.clone]

        elem_list = Tilia::VObject::ElementList.new(elems)

        count = 0
        key = nil
        elem_list.each_with_index do |subcomponent, i|
          count += 1
          key = i
          assert_kind_of(Tilia::VObject::Component, subcomponent)
        end

        assert_equal(3, count)
        assert_equal(2, key)
      end
    end
  end
end
