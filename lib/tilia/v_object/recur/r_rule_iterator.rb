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
      class RRuleIterator
        # Creates the Iterator.
        #
        # @param [String|array] rrule
        # @param [Time] start
        def initialize(rrule, start)
          @week_start = 'MO'
          @counter = 0
          @interval = 1
          @day_map = {
            'SU' => 0,
            'MO' => 1,
            'TU' => 2,
            'WE' => 3,
            'TH' => 4,
            'FR' => 5,
            'SA' => 6
          }
          @day_names = {
            0 => 'Sunday',
            1 => 'Monday',
            2 => 'Tuesday',
            3 => 'Wednesday',
            4 => 'Thursday',
            5 => 'Friday',
            6 => 'Saturday'
          }

          @start_date = start
          parse_r_rule(rrule)
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
        # iterator. This will return false if we've gone beyond the UNTIL or COUNT
        # statements.
        #
        # @return [Boolean]
        def valid
          return @counter < @count if @count
          @until.nil? || @current_date <= @until
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
          # Otherwise, we find the next event in the normal RRULE
          # sequence.
          case @frequency
          when 'hourly'
            next_hourly
          when 'daily'
            next_daily
          when 'weekly'
            next_weekly
          when 'monthly'
            next_monthly
          when 'yearly'
            next_yearly
          end

          @counter += 1
        end

        # Returns true if this recurring event never ends.
        #
        # @return [Boolean]
        def infinite?
          !@count && !@until
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

        # Does the processing for advancing the iterator for hourly frequency.
        #
        # @return [void]
        def next_hourly
          @current_date += @interval.hours
        end

        # Does the processing for advancing the iterator for daily frequency.
        #
        # @return [void]
        def next_daily
          unless @by_hour || @by_day
            @current_date += @interval.days
            return nil
          end

          recurrence_hours = hours if @by_hour
          recurrence_days = days if @by_day
          recurrence_months = months if @by_month

          loop do
            if @by_hour
              if @current_date.hour == 23
                # to obey the interval rule
                @current_date += (@interval - 1).days
              end

              @current_date += 1.hour

            else
              @current_date += @interval.days
            end

            # Current month of the year
            current_month = @current_date.month

            # Current day of the week
            current_day = @current_date.wday

            # Current hour of the day
            current_hour = @current_date.hour

            break unless (@by_day && !recurrence_days.include?(current_day)) ||
                         (@by_hour && !recurrence_hours.include?(current_hour)) ||
                         (@by_month && !recurrence_months.include?(current_month))
          end
        end

        # Does the processing for advancing the iterator for weekly frequency.
        #
        # @return [void]
        def next_weekly
          if !@by_hour && !@by_day
            @current_date += @interval.weeks
            return nil
          end

          recurrence_hours = hours if @by_hour

          recurrence_days = days if @by_day

          # First day of the week:
          first_day = @day_map[@week_start]
          loop do
            if @by_hour
              @current_date += 1.hour
            else
              @current_date += 1.day
            end

            # Current day of the week
            current_day = @current_date.wday

            # Current hour of the day
            current_hour = @current_date.hour

            # We need to roll over to the next week
            if current_day == first_day && (!@by_hour || current_hour == 0)
              @current_date += (@interval - 1).weeks

              # We need to go to the first day of this week, but only if we
              # are not already on this first day of this week.
              if @current_date.wday != first_day
                @current_date -= (@current_date.wday - first_day).days
              end
            end

            # We have a match
            break unless (@by_day && !recurrence_days.include?(current_day)) || (@by_hour && !recurrence_hours.include?(current_hour))
          end
        end

        # Does the processing for advancing the iterator for monthly frequency.
        #
        # @return [void]
        def next_monthly
          current_day_of_month = @current_date.day
          unless @by_month_day || @by_day
            # If the current day is higher than the 28th, rollover can
            # occur to the next month. We Must skip these invalid
            # entries.
            if current_day_of_month < 29
              @current_date += @interval.months
            else
              increase = 0
              temp_date = nil
              loop do
                increase += 1
                temp_date = @current_date + (@interval * increase).months
                break unless temp_date.day != current_day_of_month
              end
              @current_date = temp_date
            end
            return nil
          end

          occurrence = nil
          loop do
            occurrences = monthly_occurrences

            occurrence = nil
            stop = false
            occurrences.each do |this_occurrence|
              # The first occurrence thats higher than the current
              # day of the month wins.
              next unless this_occurrence > current_day_of_month
              occurrence = this_occurrence
              stop = true
              break
            end
            break if stop
            occurrence = occurrences.last unless occurrence

            # If we made it all the way here, it means there were no
            # valid occurrences, and we need to advance to the next
            # month.
            @current_date -= (@current_date.day - 1).days
            @current_date += @interval.months

            # This goes to 0 because we need to start counting at the
            # beginning.
            current_day_of_month = 0
          end

          @current_date += (occurrence.to_i - @current_date.day).days
        end

        # Does the processing for advancing the iterator for yearly frequency.
        #
        # @return [void]
        def next_yearly
          current_month = @current_date.month
          current_year = @current_date.year
          current_day_of_month = @current_date.day

          # No sub-rules, so we just advance by year
          unless @by_month
            # Unless it was a leap day!
            if current_month == 2 && current_day_of_month == 29
              counter = 0
              next_date = nil
              loop do
                counter += 1
                # Here we increase the year count by the interval, until
                # we hit a date that's also in a leap year.
                #
                # We could just find the next interval that's dividable by
                # 4, but that would ignore the rule that there's no leap
                # year every year that's dividable by a 100, but not by
                # 400. (1800, 1900, 2100). So we just rely on the datetime
                # functions instead.
                next_date = @current_date + (@interval * counter).years
                break if next_date.to_date.leap?
              end

              @current_date = next_date

              return nil
            end

            # The easiest form
            @current_date += @interval.years
            return nil
          end

          current_month = @current_date.month
          current_year = @current_date.year
          current_day_of_month = @current_date.day

          advanced_to_new_month = false

          occurrence = nil
          # If we got a byDay or getMonthDay filter, we must first expand
          # further.
          if @by_day || @by_month_day
            loop do
              occurrences = monthly_occurrences

              stop = false
              occurrences.each do |this_occurrence|
                # The first occurrence that's higher than the current
                # day of the month wins.
                # If we advanced to the next month or year, the first
                # occurrence is always correct.
                next unless this_occurrence > current_day_of_month || advanced_to_new_month
                occurrence = this_occurrence
                stop = true
                break
              end
              occurrence = occurrences.last unless occurrence
              break if stop

              # If we made it here, it means we need to advance to
              # the next month or year.
              current_day_of_month = 1
              advanced_to_new_month = true

              loop do
                current_month += 1
                if current_month > 12
                  current_year += @interval
                  current_month = 1
                end
                break if @by_month.include?(current_month.to_s)
              end

              @current_date = @current_date +
                              (current_year - @current_date.year).years +
                              (current_month - @current_date.month).months +
                              (current_day_of_month - @current_date.day).days
            end

            # If we made it here, it means we got a valid occurrence
            @current_date = @current_date +
                            (current_year - @current_date.year).years +
                            (current_month - @current_date.month).months +
                            (occurrence - @current_date.day).days
            return nil
          else
            # These are the 'byMonth' rules, if there are no byDay or
            # byMonthDay sub-rules.
            loop do
              current_month += 1
              if current_month > 12
                current_year += @interval
                current_month = 1
              end
              break if @by_month.include?(current_month.to_s)
            end

            @current_date = @current_date +
                            (current_year - @current_date.year).years +
                            (current_month - @current_date.month).months +
                            (current_day_of_month - @current_date.day).days

            return nil
          end
        end

        # This method receives a string from an RRULE property, and populates this
        # class with all the values.
        #
        # @param [String|array] rrule
        #
        # @return [void]
        def parse_r_rule(rrule)
          if rrule.is_a?(String)
            rrule = Property::ICalendar::Recur.string_to_array(rrule)
          end

          rrule.each do |key, value|
            key = key.upcase
            case key
            when 'FREQ'
              value = value.downcase
              unless ['secondly', 'minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'].include?(value)
                fail InvalidDataException, "Unknown value for FREQ=#{value.upcase}"
              end
              @frequency = value
            when 'UNTIL'
              @until = DateTimeParser.parse(value, @start_date.time_zone)

              # In some cases events are generated with an UNTIL=
              # parameter before the actual start of the event.
              #
              # Not sure why this is happening. We assume that the
              # intention was that the event only recurs once.
              #
              # So we are modifying the parameter so our code doesn't
              # break.
              @until = @start_date if @until < @start_date
            when 'INTERVAL', 'COUNT'
              val = value.to_i
              if val < 1
                fail InvalidDataException, "#{key.upcase} in RRULE must be a positive integer!"
              end
              key = key.downcase
              key == 'interval' ? @interval = val : @count = val
            when 'BYSECOND'
              @by_second = value.is_a?(Array) ? value : [value]
            when 'BYMINUTE'
              @by_minute = value.is_a?(Array) ? value : [value]
            when 'BYHOUR'
              @by_hour = value.is_a?(Array) ? value : [value]
            when 'BYDAY'
              value = value.is_a?(Array) ? value : [value]
              value.each do |part|
                unless part =~ /^  (-|\+)? ([1-5])? (MO|TU|WE|TH|FR|SA|SU) $/xi
                  fail InvalidDataException, "Invalid part in BYDAY clause: #{part}"
                end
              end
              @by_day = value
            when 'BYMONTHDAY'
              @by_month_day = value.is_a?(Array) ? value : [value]
            when 'BYYEARDAY'
              @by_year_day = value.is_a?(Array) ? value : [value]
            when 'BYWEEKNO'
              @by_week_no = value.is_a?(Array) ? value : [value]
            when 'BYMONTH'
              @by_month = value.is_a?(Array) ? value : [value]
            when 'BYSETPOS'
              @by_set_pos = value.is_a?(Array) ? value : [value]
            when 'WKST'
              @week_start = value.upcase
            else
              fail InvalidDataException, "Not supported: #{key.upcase}"
            end
          end
        end

        # Returns all the occurrences for a monthly frequency with a 'byDay' or
        # 'byMonthDay' expansion for the current month.
        #
        # The returned list is an array of integers with the day of month (1-31).
        #
        # @return [array]
        def monthly_occurrences
          start_date = @current_date.clone

          by_day_results = []

          # Our strategy is to simply go through the byDays, advance the date to
          # that point and add it to the results.
          if @by_day
            @by_day.each do |day|
              day_index = @day_map[day[-2..-1]]

              # Dayname will be something like 'wednesday'. Now we need to find
              # all wednesdays in this month.
              day_hits = []

              check_date = start_date - (start_date.day - 1).days
              if check_date.wday != day_index
                if day_index < check_date.wday
                  check_date += (7 - check_date.wday + day_index).days
                else
                  check_date += (day_index - check_date.wday).days
                end
              end

              loop do
                day_hits << check_date.day
                check_date += 1.week
                break unless check_date.month == start_date.month
              end

              # So now we have 'all wednesdays' for month. It is however
              # possible that the user only really wanted the 1st, 2nd or last
              # wednesday.
              if day.length > 2
                offset = day[0..-3].to_i

                if offset > 0
                  # It is possible that the day does not exist, such as a
                  # 5th or 6th wednesday of the month.
                  by_day_results << day_hits[offset - 1] if day_hits[offset - 1]
                else
                  # if it was negative we count from the end of the array
                  # might not exist, fx. -5th tuesday
                  by_day_results << day_hits[offset] if day_hits[offset]
                end
              else
                # There was no counter (first, second, last wednesdays), so we
                # just need to add the all to the list).
                by_day_results.concat(day_hits)
              end
            end
          end

          by_month_day_results = []
          if @by_month_day
            @by_month_day.each do |month_day|
              days_in_month = Time.days_in_month(start_date.month, start_date.year)
              # Removing values that are out of range for this month
              if month_day.to_i > days_in_month || month_day.to_i < 0 - days_in_month
                next
              end
              if month_day.to_i > 0
                by_month_day_results << month_day.to_i
              else
                # Negative values
                by_month_day_results << days_in_month + 1 + month_day.to_i
              end
            end
          end

          # If there was just byDay or just byMonthDay, they just specify our
          # (almost) final list. If both were provided, then byDay limits the
          # list.
          if @by_month_day && @by_day
            result = by_month_day_results & by_day_results
          elsif @by_month_day
            result = by_month_day_results
          else
            result = by_day_results
          end
          result = result.uniq
          result = result.sort

          # The last thing that needs checking is the BYSETPOS. If it's set, it
          # means only certain items in the set survive the filter.
          return result unless @by_set_pos

          filtered_result = []
          @by_set_pos.each do |set_pos|
            set_pos = set_pos.to_i

            set_pos += 1 if set_pos < 0
            filtered_result << result[set_pos - 1] if result[set_pos - 1]
          end

          filtered_result = filtered_result.sort
          filtered_result
        end

        # Simple mapping from iCalendar day names to day numbers.
        #
        # @return [array]
        # RUBY: attr_accessor :day_map

        def hours
          recurrence_hours = []
          @by_hour.each do |by_hour|
            recurrence_hours << by_hour.to_i
          end
          recurrence_hours
        end

        def days
          recurrence_days = []
          @by_day.each do |by_day|
            # The day may be preceeded with a positive (+n) or
            # negative (-n) integer. However, this does not make
            # sense in 'weekly' so we ignore it here.
            recurrence_days << @day_map[by_day[0...2]]
          end
          recurrence_days
        end

        def months
          recurrence_months = []
          @by_month.each do |by_month|
            recurrence_months << by_month.to_i
          end
          recurrence_months
        end
      end
    end
  end
end
