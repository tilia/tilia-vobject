require 'test_helper'

module Tilia
  module VObject
    class DateTimeTest < Minitest::Test
      def setup
        @vcal = Tilia::VObject::Component::VCalendar.new
      end

      def test_set_date_time
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt

        assert_equal('19850704T013000', elem.to_s)
        assert_equal('Europe/Amsterdam', elem['TZID'].to_s)
        assert_nil(elem['VALUE'])

        assert(elem.time?)
      end

      def test_set_date_time_local
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt
        elem.floating = true

        assert_equal('19850704T013000', elem.to_s)
        assert_nil(elem['TZID'])

        assert(elem.time?)
      end

      def test_set_date_time_utc
        tz = ActiveSupport::TimeZone.new('GMT')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt

        assert_equal('19850704T013000Z', elem.to_s)
        assert_nil(elem['TZID'])

        assert(elem.time?)
      end

      def test_set_date_time_from_unix_timestamp
        # When initialized from a Unix timestamp, the timezone is set to "+00:00".
        tz = ActiveSupport::TimeZone.new('GMT')
        dt = tz.at(489_288_600)

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt

        assert_equal('19850704T013000Z', elem.to_s)
        assert_nil(elem['TZID'])

        assert(elem.time?)
      end

      def test_set_date_time_localtz
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt

        assert_equal('19850704T013000', elem.to_s)
        assert_equal('Europe/Amsterdam', elem['TZID'].to_s)

        assert(elem.time?)
      end

      def test_set_date_time_date
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem['VALUE'] = 'DATE'
        elem.date_time = dt

        assert_equal('19850704', elem.to_s)
        assert_nil(elem['TZID'])
        assert_equal('DATE', elem['VALUE'].to_s)

        refute(elem.time?)
      end

      def test_set_value
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.value = dt

        assert_equal('19850704T013000', elem.to_s)
        assert_equal('Europe/Amsterdam', elem['TZID'].to_s)
        assert_nil(elem['VALUE'])

        assert(elem.time?)
      end

      def test_set_value_array
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt1 = tz.parse('1985-07-04 01:30:00')
        dt2 = tz.parse('1985-07-04 02:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.value = [dt1, dt2]

        assert_equal('19850704T013000,19850704T023000', elem.to_s)
        assert_equal('Europe/Amsterdam', elem['TZID'].to_s)
        assert_nil(elem['VALUE'])

        assert(elem.time?)
      end

      def test_set_parts
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt1 = tz.parse('1985-07-04 01:30:00')
        dt2 = tz.parse('1985-07-04 02:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.parts = [dt1, dt2]

        assert_equal('19850704T013000,19850704T023000', elem.to_s)
        assert_equal('Europe/Amsterdam', elem['TZID'].to_s)
        assert_nil(elem['VALUE'])

        assert(elem.time?)
      end

      def test_set_parts_strings
        dt1 = '19850704T013000Z'
        dt2 = '19850704T023000Z'

        elem = @vcal.create_property('DTSTART')
        elem.parts = [dt1, dt2]

        assert_equal('19850704T013000Z,19850704T023000Z', elem.to_s)
        assert_nil(elem['VALUE'])

        assert(elem.time?)
      end

      def test_get_date_time_cached
        tz = ActiveSupport::TimeZone.new('Europe/Amsterdam')
        dt = tz.parse('1985-07-04 01:30:00')

        elem = @vcal.create_property('DTSTART')
        elem.date_time = dt

        assert_equal(elem.date_time, dt)
      end

      def test_get_date_time_date_null
        elem = @vcal.create_property('DTSTART')
        dt = elem.date_time

        assert_nil(dt)
      end

      def test_get_date_time_date_date
        elem = @vcal.create_property('DTSTART', '19850704')
        dt = elem.date_time

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 00:00:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
      end

      def test_get_date_time_date_date_reference_time_zone
        elem = @vcal.create_property('DTSTART', '19850704')

        tz = ActiveSupport::TimeZone.new('America/Toronto')
        dt = elem.date_time(tz)
        dt = dt.in_time_zone(ActiveSupport::TimeZone.new('UTC'))

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 04:00:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
      end

      def test_get_date_time_date_floating
        elem = @vcal.create_property('DTSTART', '19850704T013000')
        dt = elem.date_time

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 01:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
      end

      def test_get_date_time_date_floating_reference_time_zone
        elem = @vcal.create_property('DTSTART', '19850704T013000')

        tz = ActiveSupport::TimeZone.new('America/Toronto')
        dt = elem.date_time(tz)
        dt = dt.in_time_zone(ActiveSupport::TimeZone.new('UTC'))

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 05:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
      end

      def test_get_date_time_date_utc
        elem = @vcal.create_property('DTSTART', '19850704T013000Z')
        dt = elem.date_time

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 01:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
        assert_equal('UTC', dt.time_zone.name)
      end

      def test_get_date_time_date_localtz
        elem = @vcal.create_property('DTSTART', '19850704T013000')
        elem['TZID'] = 'Europe/Amsterdam'

        dt = elem.date_time

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 01:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
        assert_equal('Europe/Amsterdam', dt.time_zone.name)
      end

      def test_get_date_time_date_invalid
        elem = @vcal.create_property('DTSTART', 'bla')
        assert_raises(InvalidDataException) do
          elem.date_time
        end
      end

      def test_get_date_time_weird_tz
        elem = @vcal.create_property('DTSTART', '19850704T013000')
        elem['TZID'] = '/freeassociation.sourceforge.net/Tzfile/Europe/Amsterdam'

        event = @vcal.create_component('VEVENT')
        event.add(elem)

        timezone = @vcal.create_component('VTIMEZONE')
        timezone['TZID'] = '/freeassociation.sourceforge.net/Tzfile/Europe/Amsterdam'
        timezone['X-LIC-LOCATION'] = 'Europe/Amsterdam'

        @vcal.add(event)
        @vcal.add(timezone)

        dt = elem.date_time

        assert_kind_of(::Time, dt)
        assert_equal('1985-07-04 01:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
        assert_equal('Europe/Amsterdam', dt.time_zone.name)
      end

      def test_get_date_time_bad_time_zone
        Time.use_zone('Canada/Eastern') do
          elem = @vcal.create_property('DTSTART', '19850704T013000')
          elem['TZID'] = 'Moon'

          event = @vcal.create_component('VEVENT')
          event.add(elem)

          timezone = @vcal.create_component('VTIMEZONE')
          timezone['TZID'] = 'Moon'
          timezone['X-LIC-LOCATION'] = 'Moon'

          @vcal.add(event)
          @vcal.add(timezone)

          dt = elem.date_time

          assert_kind_of(::Time, dt)
          assert_equal('1985-07-04 01:30:00', dt.strftime('%Y-%m-%d %H:%M:%S'))
          assert_equal('Canada/Eastern', dt.time_zone.name)
        end
      end

      def test_update_value_parameter
        dt_start = @vcal.create_property('DTSTART', Time.zone.parse('2013-06-07 15:05:00'))
        dt_start['VALUE'] = 'DATE'

        assert_equal("DTSTART;VALUE=DATE:20130607\r\n", dt_start.serialize)
      end

      def test_validate
        ex_date = @vcal.create_property('EXDATE', '-00011130T143000Z')
        messages = ex_date.validate
        assert_equal(1, messages.size)
        assert_equal(3, messages[0]['level'])
      end

      # This issue was discovered on the sabredav mailing list.
      def test_create_date_property_through_add
        vcal = Tilia::VObject::Component::VCalendar.new
        vevent = vcal.add('VEVENT')

        dtstart = vevent.add(
          'DTSTART',
          Time.zone.parse('2014-03-07'),
          'VALUE' => 'DATE'
        )

        assert_equal("DTSTART;VALUE=DATE:20140307\r\n", dtstart.serialize)
      end
    end
  end
end
