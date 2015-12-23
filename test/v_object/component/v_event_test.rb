require 'test_helper'

module Tilia
  module VObject
    class VEventTest < Minitest::Test
      def time_range_test_data
        tests = []
        berlin = ActiveSupport::TimeZone.new('Europe/Berlin')

        calendar = Tilia::VObject::Component::VCalendar.new

        vevent = calendar.create_component('VEVENT')
        vevent['DTSTART'] = '20111223T120000Z'
        tests << [vevent, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vevent2 = vevent.clone
        vevent2['DTEND'] = '20111225T120000Z'
        tests << [vevent2, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent2, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vevent3 = vevent.clone
        vevent3['DURATION'] = 'P1D'
        tests << [vevent3, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent3, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        vevent4 = vevent.clone
        vevent4['DTSTART'] = '20111225'
        vevent4['DTSTART']['VALUE'] = 'DATE'
        tests << [vevent4, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent4, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]
        # Event with no end date should be treated as lasting the entire day.
        tests << [vevent4, Time.zone.parse('2011-12-25 16:00:00'), Time.zone.parse('2011-12-25 17:00:00'), true]
        # DTEND is non inclusive so all day events should not be returned on the next day.
        tests << [vevent4, Time.zone.parse('2011-12-26 00:00:00'), Time.zone.parse('2011-12-26 17:00:00'), false]
        # The timezone of timerange in question also needs to be considered.
        tests << [vevent4, berlin.parse('2011-12-26 00:00:00'), berlin.parse('2011-12-26 17:00:00'), false]

        vevent5 = vevent.clone
        vevent5['DURATION'] = 'P1D'
        vevent5['RRULE'] = 'FREQ=YEARLY'
        tests << [vevent5, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent5, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]
        tests << [vevent5, Time.zone.parse('2013-12-01'), Time.zone.parse('2013-12-31'), true]

        vevent6 = vevent.clone
        vevent6['DTSTART'] = '20111225'
        vevent6['DTSTART']['VALUE'] = 'DATE'
        vevent6['DTEND'] = '20111225'
        vevent6['DTEND']['VALUE'] = 'DATE'

        tests << [vevent6, Time.zone.parse('2011-01-01'), Time.zone.parse('2012-01-01'), true]
        tests << [vevent6, Time.zone.parse('2011-01-01'), Time.zone.parse('2011-11-01'), false]

        # Added this test to ensure that recurrence rules with no DTEND also
        # get checked for the entire day.
        vevent7 = vevent.clone
        vevent7['DTSTART'] = '20120101'
        vevent7['DTSTART']['VALUE'] = 'DATE'
        vevent7['RRULE'] = 'FREQ=MONTHLY'
        tests << [vevent7, Time.zone.parse('2012-02-01 15:00:00'), Time.zone.parse('2012-02-02'), true]
        # The timezone of timerange in question should also be considered.
        tests << [vevent7, berlin.parse('2012-02-02 00:00:00'), berlin.parse('2012-02-03 00:00:00'), false]

        # Added this test to check recurring events that have no instances.
        vevent8 = vevent.clone
        vevent8['DTSTART'] = '20130329T140000'
        vevent8['DTEND'] = '20130329T153000'
        vevent8['RRULE'] = { 'FREQ' => 'WEEKLY', 'BYDAY' => ['FR'], 'UNTIL' => '20130412T115959Z' }
        vevent8.add('EXDATE', '20130405T140000')
        vevent8.add('EXDATE', '20130329T140000')
        tests << [vevent8, Time.zone.parse('2013-03-01'), Time.zone.parse('2013-04-01'), false]

        tests
      end

      def test_in_time_range
        time_range_test_data.each do |data|
          (vevent, start, ending, outcome) = data
          assert_equal(outcome, vevent.in_time_range?(start, ending))
        end
      end
    end
  end
end
