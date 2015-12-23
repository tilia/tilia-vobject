require 'test_helper'

module Tilia
  module VObject
    class RecurTest < Minitest::Test
      def test_parts
        vcal = Tilia::VObject::Component::VCalendar.new
        recur = vcal.add('RRULE', 'FREQ=Daily')

        assert_kind_of(Tilia::VObject::Property::ICalendar::Recur, recur)

        assert_equal({ 'FREQ' => 'DAILY' }, recur.parts)
        recur.parts = { 'freq' => 'MONTHLY' }

        assert_equal({ 'FREQ' => 'MONTHLY' }, recur.parts)
      end

      def test_set_value_bad_val
        vcal = Tilia::VObject::Component::VCalendar.new
        recur = vcal.add('RRULE', 'FREQ=Daily')
        assert_raises(ArgumentError) { recur.value = Exception.new }
      end

      def test_set_sub_parts
        vcal = Tilia::VObject::Component::VCalendar.new
        recur = vcal.add('RRULE', 'FREQ' => 'DAILY', 'BYDAY' => 'mo,tu', 'BYMONTH' => [0, 1])

        assert_equal(
          {
            'FREQ'    => 'DAILY',
            'BYDAY'   => ['MO', 'TU'],
            'BYMONTH' => [0, 1]
          },
          recur.parts
        )
      end
    end
  end
end
