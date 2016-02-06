require 'test_helper'

module Tilia
  module VObject
    class RDateIteratorTest < Minitest::Test
      def test_simple
        utc = ActiveSupport::TimeZone.new('UTC')
        it = Tilia::VObject::Recur::RDateIterator.new('20140901T000000Z,20141001T000000Z', utc.parse('2014-08-01 00:00:00'))

        expected = [
          utc.parse('2014-08-01 00:00:00'),
          utc.parse('2014-09-01 00:00:00'),
          utc.parse('2014-10-01 00:00:00')
        ]

        assert_equal(expected, it.to_a)

        refute(it.infinite?)
      end

      def test_timezone
        tz =  ActiveSupport::TimeZone.new('Europe/Berlin')
        it = Recur::RDateIterator.new('20140901T000000,20141001T000000', tz.parse('2014-08-01 00:00:00'))

        expected = [
          tz.parse('2014-08-01 00:00:00'),
          tz.parse('2014-09-01 00:00:00'),
          tz.parse('2014-10-01 00:00:00'),
        ]

        assert_equal(
          expected,
          it.to_a
        )

        refute(it.infinite?)
      end

      def test_fast_forward
        utc = ActiveSupport::TimeZone.new('UTC')
        it = Tilia::VObject::Recur::RDateIterator.new('20140901T000000Z,20141001T000000Z', utc.parse('2014-08-01 00:00:00'))

        it.fast_forward(Time.zone.parse('2014-08-15 00:00:00'))

        result = []
        while it.valid
          result << it.current
          it.next
        end

        expected = [
          utc.parse('2014-09-01 00:00:00'),
          utc.parse('2014-10-01 00:00:00')
        ]

        assert_equal(expected, result)

        refute(it.infinite?)
      end
    end
  end
end
