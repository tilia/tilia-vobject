require 'test_helper'

module Tilia
  module VObject
    class InfiniteLoopProblemTest < Minitest::Test
      def setup
        @vcal = Tilia::VObject::Component::VCalendar.new
      end

      # This bug came from a Fruux customer. This would result in a never-ending
      # request.
      def test_fast_forward_too_far
        ev = @vcal.create_component('VEVENT')
        ev['UID'] = 'foobar'
        ev['DTSTART'] = '20090420T180000Z'
        ev['RRULE'] = 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20090704T205959Z;INTERVAL=1'

        refute(ev.in_time_range?(Time.zone.parse('2012-01-01 12:00:00'), Time.zone.parse('3000-01-01 00:00:00')))
      end

      # Different bug, also likely an infinite loop.
      def test_yearly_by_month_loop
        ev = @vcal.create_component('VEVENT')
        ev['UID'] = 'uuid'
        ev['DTSTART'] = '20120101T154500'
        ev['DTSTART']['TZID'] = 'Europe/Berlin'
        ev['RRULE'] = 'FREQ=YEARLY;INTERVAL=1;UNTIL=20120203T225959Z;BYMONTH=2;BYSETPOS=1;BYDAY=SU,MO,TU,WE,TH,FR,SA'
        ev['DTEND'] = '20120101T164500'
        ev['DTEND']['TZID'] = 'Europe/Berlin'

        # This recurrence rule by itself is a yearly rule that should happen
        # every february.
        #
        # The BYDAY part expands this to every day of the month, but the
        # BYSETPOS limits this to only the 1st day of the month. Very crazy
        # way to specify this, and could have certainly been a lot easier.
        @vcal.add(ev)

        it = Tilia::VObject::Recur::EventIterator.new(@vcal, 'uuid')
        it.fast_forward(ActiveSupport::TimeZone.new('UTC').parse('2012-01-29 23:00:00'))

        collect = []

        while it.valid
          collect << it.dt_start
          if it.dt_start > ActiveSupport::TimeZone.new('UTC').parse('2013-02-05 22:59:59')
            break
          end
          it.next
        end

        assert_equal([ActiveSupport::TimeZone.new('Europe/Berlin').parse('2012-02-01 15:45:00')], collect)
      end

      # Something, somewhere produced an ics with an interval set to 0. Because
      # this means we increase the current day (or week, month) by 0, this also
      # results in an infinite loop.
      #
      # @expectedException InvalidArgumentException
      # @return void
      def test_zero_interval
        ev = @vcal.create_component('VEVENT')
        ev['UID'] = 'uuid'
        ev['DTSTART'] = '20120824T145700Z'
        ev['RRULE'] = 'FREQ=YEARLY;INTERVAL=0'
        @vcal.add(ev)

        assert_raises(InvalidDataException) do
          Tilia::VObject::Recur::EventIterator.new(@vcal, 'uuid')
        end
        # it.fast_forward(ActiveSupport::TimeZone.new('UTC').parse('2013-01-01 23:00:00'))

        # if we got this far.. it means we are no longer infinitely looping
      end
    end
  end
end
