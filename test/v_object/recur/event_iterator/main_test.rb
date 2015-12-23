require 'test_helper'

module Tilia
  module VObject
    class MainTest < Minitest::Test
      def test_values
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')
        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=DAILY;BYHOUR=10;BYMINUTE=5;BYSECOND=16;BYWEEKNO=32;BYYEARDAY=100,200'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = Time.zone.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        assert(it.infinite?)
      end

      def test_invalid_freq
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')
        ev['RRULE'] = 'FREQ=SMONTHLY;INTERVAL=3;UNTIL=20111025T000000Z'
        ev['UID'] = 'foo'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = ActiveSupport::TimeZone.new('UTC').parse('2011-10-07')

        ev.add(dt_start)
        vcal.add(ev)

        assert_raises(ArgumentError) { Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s) }
      end

      def test_v_calendar_no_uid
        vcal = Tilia::VObject::Component::VCalendar.new
        assert_raises(ArgumentError) { Tilia::VObject::Recur::EventIterator.new(vcal) }
      end

      def test_v_calendar_invalid_uid
        vcal = Tilia::VObject::Component::VCalendar.new
        assert_raises(ArgumentError) { Tilia::VObject::Recur::EventIterator.new(vcal, 'foo') }
      end

      def test_hourly
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=HOURLY;INTERVAL=3;UNTIL=20111025T000000Z'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07 12:00:00')

        ev.add(dt_start)
        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'])

        # Max is to prevent overflow
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07 12:00:00'),
            tz.parse('2011-10-07 15:00:00'),
            tz.parse('2011-10-07 18:00:00'),
            tz.parse('2011-10-07 21:00:00'),
            tz.parse('2011-10-08 00:00:00'),
            tz.parse('2011-10-08 03:00:00'),
            tz.parse('2011-10-08 06:00:00'),
            tz.parse('2011-10-08 09:00:00'),
            tz.parse('2011-10-08 12:00:00'),
            tz.parse('2011-10-08 15:00:00'),
            tz.parse('2011-10-08 18:00:00'),
            tz.parse('2011-10-08 21:00:00')
          ],
          result
        )
      end

      def test_daily
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=DAILY;INTERVAL=3;UNTIL=20111025T000000Z'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'])

        # Max is to prevent overflow
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07'),
            tz.parse('2011-10-10'),
            tz.parse('2011-10-13'),
            tz.parse('2011-10-16'),
            tz.parse('2011-10-19'),
            tz.parse('2011-10-22'),
            tz.parse('2011-10-25')
          ],
          result
        )
      end

      def test_no_rrule
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'])

        # Max is to prevent overflow
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal([tz.parse('2011-10-07')], result)
      end

      def test_daily_by_day_by_hour
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=DAILY;BYDAY=SA,SU;BYHOUR=6,7'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-08 06:00:00')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-08 06:00:00'),
            tz.parse('2011-10-08 07:00:00'),
            tz.parse('2011-10-09 06:00:00'),
            tz.parse('2011-10-09 07:00:00'),
            tz.parse('2011-10-15 06:00:00'),
            tz.parse('2011-10-15 07:00:00'),
            tz.parse('2011-10-16 06:00:00'),
            tz.parse('2011-10-16 07:00:00'),
            tz.parse('2011-10-22 06:00:00'),
            tz.parse('2011-10-22 07:00:00'),
            tz.parse('2011-10-23 06:00:00'),
            tz.parse('2011-10-23 07:00:00')
          ],
          result
        )
      end

      def test_daily_by_hour
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=DAILY;INTERVAL=2;BYHOUR=10,11,12,13,14,15'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2012-10-11 12:00:00')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2012-10-11 12:00:00'),
            tz.parse('2012-10-11 13:00:00'),
            tz.parse('2012-10-11 14:00:00'),
            tz.parse('2012-10-11 15:00:00'),
            tz.parse('2012-10-13 10:00:00'),
            tz.parse('2012-10-13 11:00:00'),
            tz.parse('2012-10-13 12:00:00'),
            tz.parse('2012-10-13 13:00:00'),
            tz.parse('2012-10-13 14:00:00'),
            tz.parse('2012-10-13 15:00:00'),
            tz.parse('2012-10-15 10:00:00'),
            tz.parse('2012-10-15 11:00:00')
          ],
          result
        )
      end

      def test_daily_by_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=DAILY;INTERVAL=2;BYDAY=TU,WE,FR'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07'),
            tz.parse('2011-10-11'),
            tz.parse('2011-10-19'),
            tz.parse('2011-10-21'),
            tz.parse('2011-10-25'),
            tz.parse('2011-11-02'),
            tz.parse('2011-11-04'),
            tz.parse('2011-11-08'),
            tz.parse('2011-11-16'),
            tz.parse('2011-11-18'),
            tz.parse('2011-11-22'),
            tz.parse('2011-11-30')
          ],
          result
        )
      end

      def test_weekly
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=WEEKLY;INTERVAL=2;COUNT=10'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Max is to prevent overflow
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07'),
            tz.parse('2011-10-21'),
            tz.parse('2011-11-04'),
            tz.parse('2011-11-18'),
            tz.parse('2011-12-02'),
            tz.parse('2011-12-16'),
            tz.parse('2011-12-30'),
            tz.parse('2012-01-13'),
            tz.parse('2012-01-27'),
            tz.parse('2012-02-10')
          ],
          result
        )
      end

      def test_weekly_by_day_by_hour
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,WE,FR;WKST=MO;BYHOUR=8,9,10'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07 08:00:00')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 15
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07 08:00:00'),
            tz.parse('2011-10-07 09:00:00'),
            tz.parse('2011-10-07 10:00:00'),
            tz.parse('2011-10-18 08:00:00'),
            tz.parse('2011-10-18 09:00:00'),
            tz.parse('2011-10-18 10:00:00'),
            tz.parse('2011-10-19 08:00:00'),
            tz.parse('2011-10-19 09:00:00'),
            tz.parse('2011-10-19 10:00:00'),
            tz.parse('2011-10-21 08:00:00'),
            tz.parse('2011-10-21 09:00:00'),
            tz.parse('2011-10-21 10:00:00'),
            tz.parse('2011-11-01 08:00:00'),
            tz.parse('2011-11-01 09:00:00'),
            tz.parse('2011-11-01 10:00:00')
          ],
          result
        )
      end

      def test_weekly_by_day_specific_hour
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,WE,FR;WKST=SU'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07 18:00:00')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07 18:00:00'),
            tz.parse('2011-10-18 18:00:00'),
            tz.parse('2011-10-19 18:00:00'),
            tz.parse('2011-10-21 18:00:00'),
            tz.parse('2011-11-01 18:00:00'),
            tz.parse('2011-11-02 18:00:00'),
            tz.parse('2011-11-04 18:00:00'),
            tz.parse('2011-11-15 18:00:00'),
            tz.parse('2011-11-16 18:00:00'),
            tz.parse('2011-11-18 18:00:00'),
            tz.parse('2011-11-29 18:00:00'),
            tz.parse('2011-11-30 18:00:00')
          ],
          result
        )
      end

      def test_weekly_by_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,WE,FR;WKST=SU'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # Grabbing the next 12 items
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07'),
            tz.parse('2011-10-18'),
            tz.parse('2011-10-19'),
            tz.parse('2011-10-21'),
            tz.parse('2011-11-01'),
            tz.parse('2011-11-02'),
            tz.parse('2011-11-04'),
            tz.parse('2011-11-15'),
            tz.parse('2011-11-16'),
            tz.parse('2011-11-18'),
            tz.parse('2011-11-29'),
            tz.parse('2011-11-30')
          ],
          result
        )
      end

      def test_monthly
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;INTERVAL=3;COUNT=5'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-12-05')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 14
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-12-05'),
            tz.parse('2012-03-05'),
            tz.parse('2012-06-05'),
            tz.parse('2012-09-05'),
            tz.parse('2012-12-05')
          ],
          result
        )
      end

      def test_monthly_end_of_month
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;INTERVAL=2;COUNT=12'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-12-31')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 14
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-12-31'),
            tz.parse('2012-08-31'),
            tz.parse('2012-10-31'),
            tz.parse('2012-12-31'),
            tz.parse('2013-08-31'),
            tz.parse('2013-10-31'),
            tz.parse('2013-12-31'),
            tz.parse('2014-08-31'),
            tz.parse('2014-10-31'),
            tz.parse('2014-12-31'),
            tz.parse('2015-08-31'),
            tz.parse('2015-10-31')
          ],
          result
        )
      end

      def test_monthly_by_month_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;INTERVAL=5;COUNT=9;BYMONTHDAY=1,31,-7'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-01-01')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 14
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-01-01'),
            tz.parse('2011-01-25'),
            tz.parse('2011-01-31'),
            tz.parse('2011-06-01'),
            tz.parse('2011-06-24'),
            tz.parse('2011-11-01'),
            tz.parse('2011-11-24'),
            tz.parse('2012-04-01'),
            tz.parse('2012-04-24')
          ],
          result
        )
      end

      # A pretty slow test. Had to be marked as 'medium' for phpunit to not die
      # after 1 second. Would be good to optimize later.
      def test_monthly_by_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;INTERVAL=2;COUNT=16;BYDAY=MO,-2TU,+1WE,3TH'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-01-03')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-01-03'),
            tz.parse('2011-01-05'),
            tz.parse('2011-01-10'),
            tz.parse('2011-01-17'),
            tz.parse('2011-01-18'),
            tz.parse('2011-01-20'),
            tz.parse('2011-01-24'),
            tz.parse('2011-01-31'),
            tz.parse('2011-03-02'),
            tz.parse('2011-03-07'),
            tz.parse('2011-03-14'),
            tz.parse('2011-03-17'),
            tz.parse('2011-03-21'),
            tz.parse('2011-03-22'),
            tz.parse('2011-03-28'),
            tz.parse('2011-05-02')
          ],
          result
        )
      end

      def test_monthly_by_day_by_month_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;COUNT=10;BYDAY=MO;BYMONTHDAY=1'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-08-01')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-08-01'),
            tz.parse('2012-10-01'),
            tz.parse('2013-04-01'),
            tz.parse('2013-07-01'),
            tz.parse('2014-09-01'),
            tz.parse('2014-12-01'),
            tz.parse('2015-06-01'),
            tz.parse('2016-02-01'),
            tz.parse('2016-08-01'),
            tz.parse('2017-05-01')
          ],
          result
        )
      end

      def test_monthly_by_day_by_set_pos
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=MONTHLY;COUNT=10;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1,-1'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-01-03')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-01-03'),
            tz.parse('2011-01-31'),
            tz.parse('2011-02-01'),
            tz.parse('2011-02-28'),
            tz.parse('2011-03-01'),
            tz.parse('2011-03-31'),
            tz.parse('2011-04-01'),
            tz.parse('2011-04-29'),
            tz.parse('2011-05-02'),
            tz.parse('2011-05-31')
          ],
          result
        )
      end

      def test_yearly
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=10;INTERVAL=3'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-01-01')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-01-01'),
            tz.parse('2014-01-01'),
            tz.parse('2017-01-01'),
            tz.parse('2020-01-01'),
            tz.parse('2023-01-01'),
            tz.parse('2026-01-01'),
            tz.parse('2029-01-01'),
            tz.parse('2032-01-01'),
            tz.parse('2035-01-01'),
            tz.parse('2038-01-01')
          ],
          result
        )
      end

      def test_yearly_leap_year
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=3'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2012-02-29')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2012-02-29'),
            tz.parse('2016-02-29'),
            tz.parse('2020-02-29')
          ],
          result
        )
      end

      def test_yearly_by_month
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=8;INTERVAL=4;BYMONTH=4,10'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-04-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-04-07'),
            tz.parse('2011-10-07'),
            tz.parse('2015-04-07'),
            tz.parse('2015-10-07'),
            tz.parse('2019-04-07'),
            tz.parse('2019-10-07'),
            tz.parse('2023-04-07'),
            tz.parse('2023-10-07')
          ],
          result
        )
      end

      def test_yearly_by_month_by_day
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=8;INTERVAL=5;BYMONTH=4,10;BYDAY=1MO,-1SU'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-04-04')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-04-04'),
            tz.parse('2011-04-24'),
            tz.parse('2011-10-03'),
            tz.parse('2011-10-30'),
            tz.parse('2016-04-04'),
            tz.parse('2016-04-24'),
            tz.parse('2016-10-03'),
            tz.parse('2016-10-30')
          ],
          result
        )
      end

      def test_fast_forward
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=8;INTERVAL=5;BYMONTH=4,10;BYDAY=1MO,-1SU'
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-04-04')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        # The idea is that we're fast-forwarding too far in the future, so
        # there will be no results left.
        it.fast_forward(tz.parse('2020-05-05'))

        max = 20
        result = []
        while it.valid
          result << it.current
          max -= 1

          break if max == 0
          it.next
        end

        assert_equal([], result)
      end

      def test_complex_exclusions
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('Canada/Eastern')

        ev['UID'] = 'bla'
        ev['RRULE'] = 'FREQ=YEARLY;COUNT=10'
        dt_start = vcal.create_property('DTSTART')

        dt_start.date_time = tz.parse('2011-01-01 13:50:20')

        ex_date1 = vcal.create_property('EXDATE')
        ex_date1.date_times = [tz.parse('2012-01-01 13:50:20'), tz.parse('2014-01-01 13:50:20')]
        ex_date2 = vcal.create_property('EXDATE')
        ex_date2.date_times = [tz.parse('2016-01-01 13:50:20')]

        ev.add(dt_start)
        ev.add(ex_date1)
        ev.add(ex_date2)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'].to_s)

        max = 20
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-01-01 13:50:20'),
            tz.parse('2013-01-01 13:50:20'),
            tz.parse('2015-01-01 13:50:20'),
            tz.parse('2017-01-01 13:50:20'),
            tz.parse('2018-01-01 13:50:20'),
            tz.parse('2019-01-01 13:50:20'),
            tz.parse('2020-01-01 13:50:20')
          ],
          result
        )
      end

      def test_overriden_event
        vcal = Tilia::VObject::Component::VCalendar.new

        ev1 = vcal.create_component('VEVENT')
        ev1['UID'] = 'overridden'
        ev1['RRULE'] = 'FREQ=DAILY;COUNT=10'
        ev1['DTSTART'] = '20120107T120000Z'
        ev1['SUMMARY'] = 'baseEvent'

        vcal.add(ev1)

        # ev2 overrides an event, and puts it on 2pm instead.
        ev2 = vcal.create_component('VEVENT')
        ev2['UID'] = 'overridden'
        ev2['RECURRENCE-ID'] = '20120110T120000Z'
        ev2['DTSTART'] = '20120110T140000Z'
        ev2['SUMMARY'] = 'Event 2'

        vcal.add(ev2)

        # ev3 overrides an event, and puts it 2 days and 2 hours later
        ev3 = vcal.create_component('VEVENT')
        ev3['UID'] = 'overridden'
        ev3['RECURRENCE-ID'] = '20120113T120000Z'
        ev3['DTSTART'] = '20120115T140000Z'
        ev3['SUMMARY'] = 'Event 3'

        vcal.add(ev3)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, 'overridden')

        dates = []
        summaries = []
        while it.valid
          dates << it.dt_start
          summaries << it.event_object['SUMMARY'].to_s
          it.next
        end

        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2012-01-07 12:00:00'),
            tz.parse('2012-01-08 12:00:00'),
            tz.parse('2012-01-09 12:00:00'),
            tz.parse('2012-01-10 14:00:00'),
            tz.parse('2012-01-11 12:00:00'),
            tz.parse('2012-01-12 12:00:00'),
            tz.parse('2012-01-14 12:00:00'),
            tz.parse('2012-01-15 12:00:00'),
            tz.parse('2012-01-15 14:00:00'),
            tz.parse('2012-01-16 12:00:00')
          ],
          dates
        )

        assert_equal(
          [
            'baseEvent',
            'baseEvent',
            'baseEvent',
            'Event 2',
            'baseEvent',
            'baseEvent',
            'baseEvent',
            'baseEvent',
            'Event 3',
            'baseEvent'
          ],
          summaries
        )
      end

      def test_overriden_event2
        vcal = Tilia::VObject::Component::VCalendar.new

        ev1 = vcal.create_component('VEVENT')
        ev1['UID'] = 'overridden'
        ev1['RRULE'] = 'FREQ=WEEKLY;COUNT=3'
        ev1['DTSTART'] = '20120112T120000Z'
        ev1['SUMMARY'] = 'baseEvent'

        vcal.add(ev1)

        # ev2 overrides an event, and puts it 6 days earlier instead.
        ev2 = vcal.create_component('VEVENT')
        ev2['UID'] = 'overridden'
        ev2['RECURRENCE-ID'] = '20120119T120000Z'
        ev2['DTSTART'] = '20120113T120000Z'
        ev2['SUMMARY'] = 'Override!'

        vcal.add(ev2)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, 'overridden')

        dates = []
        summaries = []
        while it.valid
          dates << it.dt_start
          summaries << it.event_object['SUMMARY'].to_s
          it.next
        end

        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2012-01-12 12:00:00'),
            tz.parse('2012-01-13 12:00:00'),
            tz.parse('2012-01-26 12:00:00')
          ],
          dates
        )

        assert_equal(
          [
            'baseEvent',
            'Override!',
            'baseEvent'
          ],
          summaries
        )
      end

      def test_overriden_event_no_values_expected
        vcal = Tilia::VObject::Component::VCalendar.new
        ev1 = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev1['UID'] = 'overridden'
        ev1['RRULE'] = 'FREQ=WEEKLY;COUNT=3'
        ev1['DTSTART'] = '20120124T120000Z'
        ev1['SUMMARY'] = 'baseEvent'

        vcal.add(ev1)

        # ev2 overrides an event, and puts it 6 days earlier instead.
        ev2 = vcal.create_component('VEVENT')
        ev2['UID'] = 'overridden'
        ev2['RECURRENCE-ID'] = '20120131T120000Z'
        ev2['DTSTART'] = '20120125T120000Z'
        ev2['SUMMARY'] = 'Override!'

        vcal.add(ev2)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, 'overridden')

        dates = []
        summaries = []

        # The reported problem was specifically related to the VCALENDAR
        # expansion. In this parcitular case, we had to forward to the 28th of
        # january.
        it.fast_forward(tz.parse('2012-01-28 23:00:00'))

        # We stop the loop when it hits the 6th of februari. Normally this
        # iterator would hit 24, 25 (overriden from 31) and 7 feb but because
        # we 'filter' from the 28th till the 6th, we should get 0 results.
        while it.valid && it.dt_start < tz.parse('2012-02-06 23:00:00')
          dates << it.dt_start
          summaries << it.event_object['SUMMARY'].to_s
          it.next
        end

        assert_equal([], dates)
        assert_equal([], summaries)
      end

      def test_rdate
        vcal = Tilia::VObject::Component::VCalendar.new
        ev = vcal.create_component('VEVENT')

        tz = ActiveSupport::TimeZone.new('UTC')

        ev['UID'] = 'bla'
        ev['RDATE'] = [
          tz.parse('2014-08-07'),
          tz.parse('2014-08-08')
        ]
        dt_start = vcal.create_property('DTSTART')
        dt_start.date_time = tz.parse('2011-10-07')

        ev.add(dt_start)

        vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(vcal, ev['UID'])

        # Max is to prevent overflow
        max = 12
        result = []
        it.each do |item|
          result << item
          max -= 1

          break if max == 0
        end

        assert_equal(
          [
            tz.parse('2011-10-07'),
            tz.parse('2014-08-07'),
            tz.parse('2014-08-08')
          ],
          result
        )
      end

      def test_no_master_bad_uid
        vcal = Tilia::VObject::Component::VCalendar.new
        # ev2 overrides an event, and puts it on 2pm instead.
        ev2 = vcal.create_component('VEVENT')
        ev2['UID'] = 'overridden'
        ev2['RECURRENCE-ID'] = '20120110T120000Z'
        ev2['DTSTART'] = '20120110T140000Z'
        ev2['SUMMARY'] = 'Event 2'

        vcal.add(ev2)

        # ev3 overrides an event, and puts it 2 days and 2 hours later
        ev3 = vcal.create_component('VEVENT')
        ev3['UID'] = 'overridden'
        ev3['RECURRENCE-ID'] = '20120113T120000Z'
        ev3['DTSTART'] = '20120115T140000Z'
        ev3['SUMMARY'] = 'Event 3'

        vcal.add(ev3)

        assert_raises(ArgumentError) { Tilia::VObject::Recur::EventIterator.new(vcal, 'broken') }
      end
    end
  end
end
