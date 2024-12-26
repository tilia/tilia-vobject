module Tilia
  module VObject
    module Recur
      # RRuleParser.
      #
      # This class receives an RRULE string, and allows you to iterate to get a list
      # of dates in that recurrence.
      #
      # For instance, passing: FREQ=DAILY;LIMIT=5 will cause the iterator to contain
      # 5 items, one for each day.
      class RDateIterator
        include Enumerable

        # Creates the Iterator.
        #
        # @param [String|array] rrule
        # @param [Time] start
        def initialize(rrule, start)
          @counter = 0
          @dates = []
          @start_date = start
          parse_r_date(rrule)
          @current_date = @start_date.clone
        end

        def current
          return nil unless valid
          @current_date.clone
        end

        # Returns the current item number.
        #
        # @return [Integer]
        def key
          @counter
        end

        # Returns whether the current item is a valid item for the recurrence
        # iterator.
        #
        # @return [Boolean]
        def valid
          @counter <= @dates.size
        end

        # Resets the iterator.
        #
        # @return [void]
        def rewind
          @current_date = @start_date.clone
          @counter = 0
        end

        # Goes on to the next iteration.
        #
        # @return [void]
        def next
          @counter += 1

          return nil unless valid

          @current_date = DateTimeParser.parse(
            @dates[@counter - 1],
            @start_date.time_zone
          )
        end

        # Returns true if this recurring event never ends.
        #
        # @return [Boolean]
        def infinite?
          false
        end

        # This method allows you to quickly go to the next occurrence after the
        # specified date.
        #
        # @param [Time] dt
        #
        # @return [void]
        def fast_forward(dt)
          self.next while valid && @current_date < dt
        end

        protected

        # This method receives a string from an RRULE property, and populates this
        # class with all the values.
        #
        # @param [String|array] rrule
        #
        # @return [void]
        def parse_r_date(rdate)
          rdate = rdate.split(',') if rdate.is_a?(String)

          @dates = rdate
        end

        def each
          m = [@start_date.clone]
          n = @dates.map do |d|
            DateTimeParser.parse(d, @start_date.time_zone)
          end
          m.concat n
          m.each do |d|
            yield(d)
          end
        end
      end
    end
  end
end
