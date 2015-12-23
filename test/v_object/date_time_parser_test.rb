require 'test_helper'

module Tilia
  module VObject
    class DateTimeParserTest < Minitest::Test
      def setup
        @utc = ActiveSupport::TimeZone.new('UTC')
      end

      def vcard_dates
        [
          [
            '19961022T140000',
            {
              'year'     => 1996,
              'month'    => 10,
              'date'     => 22,
              'hour'     => 14,
              'minute'   => 00,
              'second'   => 00,
              'timezone' => nil
            }
          ],
          [
            '--1022T1400',
            {
              'year'     => nil,
              'month'    => 10,
              'date'     => 22,
              'hour'     => 14,
              'minute'   => 00,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '---22T14',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => 22,
              'hour'     => 14,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '19850412',
            {
              'year'     => 1985,
              'month'    => 4,
              'date'     => 12,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '1985-04',
            {
              'year'     => 1985,
              'month'    => 04,
              'date'     => nil,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '1985',
            {
              'year'     => 1985,
              'month'    => nil,
              'date'     => nil,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '--0412',
            {
              'year'     => nil,
              'month'    => 4,
              'date'     => 12,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            '---12',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => 12,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            'T102200',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => 10,
              'minute'   => 22,
              'second'   => 0,
              'timezone' => nil
            }
          ],
          [
            'T1022',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => 10,
              'minute'   => 22,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            'T10',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => 10,
              'minute'   => nil,
              'second'   => nil,
              'timezone' => nil
            }
          ],
          [
            'T-2200',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => nil,
              'minute'   => 22,
              'second'   => 00,
              'timezone' => nil
            }
          ],
          [
            'T--00',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => nil,
              'minute'   => nil,
              'second'   => 00,
              'timezone' => nil
            }
          ],
          [
            'T102200Z',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => 10,
              'minute'   => 22,
              'second'   => 00,
              'timezone' => 'Z'
            }
          ],
          [
            'T102200-0800',
            {
              'year'     => nil,
              'month'    => nil,
              'date'     => nil,
              'hour'     => 10,
              'minute'   => 22,
              'second'   => 00,
              'timezone' => '-0800'
            }
          ],

          # extended format
          [
            '2012-11-29T15:10:53Z',
            {
              'year'     => 2012,
              'month'    => 11,
              'date'     => 29,
              'hour'     => 15,
              'minute'   => 10,
              'second'   => 53,
              'timezone' => 'Z'
            }
          ],

          # with milliseconds
          [
            '20121129T151053.123Z',
            {
              'year'     => 2012,
              'month'    => 11,
              'date'     => 29,
              'hour'     => 15,
              'minute'   => 10,
              'second'   => 53,
              'timezone' => 'Z'
            }
          ],

          # extended format with milliseconds
          [
            '2012-11-29T15:10:53.123Z',
            {
              'year'     => 2012,
              'month'    => 11,
              'date'     => 29,
              'hour'     => 15,
              'minute'   => 10,
              'second'   => 53,
              'timezone' => 'Z'
            }
          ]
        ]
      end

      def assert_date_and_or_time_equals_to(date, parts)
        expected = {
          'year'     => nil,
          'month'    => nil,
          'date'     => nil,
          'hour'     => nil,
          'minute'   => nil,
          'second'   => nil,
          'timezone' => nil
        }.merge parts
        assert_equal(expected, Tilia::VObject::DateTimeParser.parse_v_card_date_and_or_time(date))
      end

      def test_parse_i_calendar_duration
        assert_equal('+1 weeks', Tilia::VObject::DateTimeParser.parse_duration('P1W', true))
        assert_equal('+5 days', Tilia::VObject::DateTimeParser.parse_duration('P5D', true))
        assert_equal('+5 days 3 hours 50 minutes 12 seconds', Tilia::VObject::DateTimeParser.parse_duration('P5DT3H50M12S', true))
        assert_equal('-1 weeks 50 minutes', Tilia::VObject::DateTimeParser.parse_duration('-P1WT50M', true))
        assert_equal('+50 days 3 hours 2 seconds', Tilia::VObject::DateTimeParser.parse_duration('+P50DT3H2S', true))
        assert_equal('+0 seconds', Tilia::VObject::DateTimeParser.parse_duration('+PT0S', true))
        assert_equal(0.seconds, Tilia::VObject::DateTimeParser.parse_duration('PT0S'))
      end

      def test_parse_i_calendar_duration_date_interval
        expected = 7.days
        assert_equal(expected, Tilia::VObject::DateTimeParser.parse_duration('P1W'))
        assert_equal(expected, Tilia::VObject::DateTimeParser.parse('P1W'))

        expected = -3.minutes
        assert_equal(expected, Tilia::VObject::DateTimeParser.parse_duration('-PT3M'))
      end

      def test_parse_i_calendar_duration_fail
        assert_raises(RuntimeError) { Tilia::VObject::DateTimeParser.parse_duration('P1X', true) }
      end

      def test_parse_i_calendar_date_time
        date_time = Tilia::VObject::DateTimeParser.parse_date_time('20100316T141405')

        compare = @utc.parse('2010-03-16 14:14:05')

        assert_equal(compare, date_time)
      end

      def test_parse_i_calendar_date_time_bad_format
        assert_raises(RuntimeError) { Tilia::VObject::DateTimeParser.parse_date_time('20100316T141405 ') }
      end

      def test_parse_i_calendar_date_time_utc
        date_time = Tilia::VObject::DateTimeParser.parse_date_time('20100316T141405Z')

        compare = @utc.parse('2010-03-16 14:14:05')
        assert_equal(compare, date_time)
      end

      def test_parse_i_calendar_date_time_utc2
        date_time = Tilia::VObject::DateTimeParser.parse_date_time('20101211T160000Z')

        compare = @utc.parse('2010-12-11 16:00:00')
        assert_equal(compare, date_time)
      end

      def test_parse_i_calendar_date_time_custom_time_zone
        date_time = Tilia::VObject::DateTimeParser.parse_date_time('20100316T141405', ActiveSupport::TimeZone.new('Europe/Amsterdam'))

        compare = @utc.parse('2010-03-16 13:14:05')
        assert_equal(compare, date_time)
      end

      def test_parse_i_calendar_date
        date_time = Tilia::VObject::DateTimeParser.parse_date('20100316')

        expected = @utc.parse('2010-03-16 00:00:00')
        assert_equal(expected, date_time)

        date_time = Tilia::VObject::DateTimeParser.parse('20100316')
        assert_equal(expected, date_time)
      end

      # TCheck if a date with year > 4000 will not throw an exception. iOS seems
      # to use 45001231 in yearly recurring events
      def test_parse_i_calendar_date_greater_than4000
        date_time = Tilia::VObject::DateTimeParser.parse_date('45001231')

        expected = @utc.parse('4500-12-31 00:00:00')
        assert_equal(expected, date_time)

        date_time = Tilia::VObject::DateTimeParser.parse('45001231')
        assert_equal(expected, date_time)
      end

      # Check if a datetime with year > 4000 will not throw an exception. iOS
      # seems to use 45001231T235959 in yearly recurring events
      def test_parse_i_calendar_date_time_greater_than4000
        date_time = Tilia::VObject::DateTimeParser.parse_date_time('45001231T235959')

        expected = @utc.parse('4500-12-31 23:59:59')
        assert_equal(expected, date_time)

        date_time = Tilia::VObject::DateTimeParser.parse('45001231T235959')
        assert_equal(expected, date_time)
      end

      def test_parse_i_calendar_date_bad_format
        assert_raises(RuntimeError) { Tilia::VObject::DateTimeParser.parse_date('20100316T141405') }
      end

      def test_v_card_date
        vcard_dates.each do |data|
          (input, output) = data
          assert_equal(output, Tilia::VObject::DateTimeParser.parse_v_card_date_time(input))
        end
      end

      def test_bad_v_card_date
        assert_raises(ArgumentError) { Tilia::VObject::DateTimeParser.parse_v_card_date_time('1985---01') }
      end

      def test_bad_v_card_time
        assert_raises(ArgumentError) { Tilia::VObject::DateTimeParser.parse_v_card_time('23:12:166') }
      end

      def test_date_and_or_time_date_with_year_month_day
        assert_date_and_or_time_equals_to(
          '20150128',
          'year'  => '2015',
          'month' => '01',
          'date'  => '28'
        )
      end

      def test_date_and_or_time_date_with_year_month
        assert_date_and_or_time_equals_to(
          '2015-01',
          'year'  => '2015',
          'month' => '01'
        )
      end

      def test_date_and_or_time_date_with_month
        assert_date_and_or_time_equals_to(
          '--01',
          'month' => '01'
        )
      end

      def test_date_and_or_time_date_with_month_day
        assert_date_and_or_time_equals_to(
          '--0128',
          'month' => '01',
          'date'  => '28'
        )
      end

      def test_date_and_or_time_date_with_day
        assert_date_and_or_time_equals_to(
          '---28',
          'date' => '28'
        )
      end

      def test_date_and_or_time_time_with_hour
        assert_date_and_or_time_equals_to(
          '13',
          'hour' => '13'
        )
      end

      def test_date_and_or_time_time_with_hour_minute
        assert_date_and_or_time_equals_to(
          '1353',
          'hour'   => '13',
          'minute' => '53'
        )
      end

      def test_date_and_or_time_time_with_hour_second
        assert_date_and_or_time_equals_to(
          '135301',
          'hour'   => '13',
          'minute' => '53',
          'second' => '01'

        )
      end

      def test_date_and_or_time_time_with_minute
        assert_date_and_or_time_equals_to(
          '-53',
          'minute' => '53'
        )
      end

      def test_date_and_or_time_time_with_minute_second
        assert_date_and_or_time_equals_to(
          '-5301',
          'minute' => '53',
          'second' => '01'
        )
      end

      def test_date_and_or_time_time_with_second
        assert(true)

        # This is unreachable due to a conflict between date and time pattern.
        # This is an error in the specification, not in our implementation.
      end

      def test_date_and_or_time_time_with_second_z
        assert_date_and_or_time_equals_to(
          '--01Z',
          'second'   => '01',
          'timezone' => 'Z'
        )
      end

      def test_date_and_or_time_time_with_second_tz
        assert_date_and_or_time_equals_to(
          '--01+1234',
          'second'   => '01',
          'timezone' => '+1234'
        )
      end

      def test_date_and_or_time_date_time_with_year_month_day_hour
        assert_date_and_or_time_equals_to(
          '20150128T13',
          'year'  => '2015',
          'month' => '01',
          'date'  => '28',
          'hour'  => '13'
        )
      end

      def test_date_and_or_time_date_time_with_month_day_hour
        assert_date_and_or_time_equals_to(
          '--0128T13',
          'month' => '01',
          'date'  => '28',
          'hour'  => '13'
        )
      end

      def test_date_and_or_time_date_time_with_day_hour
        assert_date_and_or_time_equals_to(
          '---28T13',
          'date' => '28',
          'hour' => '13'
        )
      end

      def test_date_and_or_time_date_time_with_day_hour_minute
        assert_date_and_or_time_equals_to(
          '---28T1353',
          'date'   => '28',
          'hour'   => '13',
          'minute' => '53'
        )
      end

      def test_date_and_or_time_date_time_with_day_hour_minute_second
        assert_date_and_or_time_equals_to(
          '---28T135301',
          'date'   => '28',
          'hour'   => '13',
          'minute' => '53',
          'second' => '01'
        )
      end

      def test_date_and_or_time_date_time_with_day_hour_z
        assert_date_and_or_time_equals_to(
          '---28T13Z',
          'date'     => '28',
          'hour'     => '13',
          'timezone' => 'Z'
        )
      end

      def test_date_and_or_time_date_time_with_day_hour_tz
        assert_date_and_or_time_equals_to(
          '---28T13+1234',
          'date'     => '28',
          'hour'     => '13',
          'timezone' => '+1234'
        )
      end
    end
  end
end
