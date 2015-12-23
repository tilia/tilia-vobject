module Tilia
  module VObject
    module Recur
      # This class is used to determine new for a recurring event, when the next
      # events occur.
      #
      # This iterator may loop infinitely in the future, therefore it is important
      # that if you use this class, you set hard limits for the amount of iterations
      # you want to handle.
      #
      # Note that currently there is not full support for the entire iCalendar
      # specification, as it's very complex and contains a lot of permutations
      # that's not yet used very often in software.
      #
      # For the focus has been on features as they actually appear in Calendaring
      # software, but this may well get expanded as needed / on demand
      #
      # The following RRULE properties are supported
      #   * UNTIL
      #   * INTERVAL
      #   * COUNT
      #   * FREQ=DAILY
      #     * BYDAY
      #     * BYHOUR
      #     * BYMONTH
      #   * FREQ=WEEKLY
      #     * BYDAY
      #     * BYHOUR
      #     * WKST
      #   * FREQ=MONTHLY
      #     * BYMONTHDAY
      #     * BYDAY
      #     * BYSETPOS
      #   * FREQ=YEARLY
      #     * BYMONTH
      #     * BYMONTHDAY (only if BYMONTH is also set)
      #     * BYDAY (only if BYMONTH is also set)
      #
      # Anything beyond this is 'undefined', which means that it may get ignored, or
      # you may get unexpected results. The effect is that in some applications the
      # specified recurrence may look incorrect, or is missing.
      #
      # The recurrence iterator also does not yet support THISANDFUTURE.
      class EventIterator
        # Reference timeZone for floating dates and times.
        #
        # @var DateTimeZone
        # RUBY: attr_accessor :time_zone

        # True if we're iterating an all-day event.
        #
        # @var bool
        # RUBY: attr_accessor :all_day

        # Creates the iterator.
        #
        # There's three ways to set up the iterator.
        #
        # 1. You can pass a VCALENDAR component and a UID.
        # 2. You can pass an array of VEVENTs (all UIDS should match).
        # 3. You can pass a single VEVENT component.
        #
        # Only the second method is recomended. The other 1 and 3 will be removed
        # at some point in the future.
        #
        # The uid parameter is only required for the first method.
        #
        # @param Component|array input
        # @param string|null uid
        # @param DateTimeZone time_zone Reference timezone for floating dates and
        #                               times.
        def initialize(input, uid = nil, time_zone = nil)
          @overridden_events = []
          @exceptions = {}
          @all_day = false

          time_zone = ActiveSupport::TimeZone.new('UTC') if time_zone.nil?

          @time_zone = time_zone

          if input.is_a?(Array)
            events = input
          elsif input.is_a?(Component::VEvent)
            # Single instance mode.
            events = [input]
          else
            # Calendar + UID mode.
            uid = uid.to_s
            if uid.blank?
              fail ArgumentError, 'The UID argument is required when a VCALENDAR is passed to this constructor'
            end
            unless input.key?('VEVENT')
              fail ArgumentError, 'No events found in this calendar'
            end

            events = input.by_uid(uid)
          end

          events.each do |vevent|
            if !vevent.key?('RECURRENCE-ID')
              @master_event = vevent
            else
              @exceptions[vevent['RECURRENCE-ID'].date_time(@time_zone).to_i] = true
              @overridden_events << vevent
            end
          end

          unless @master_event
            # No base event was found. CalDAV does allow cases where only
            # overridden instances are stored.
            #
            # In this particular case, we're just going to grab the first
            # event and use that instead. This may not always give the
            # desired result.
            if @overridden_events.size == 0
              fail ArgumentError, "This VCALENDAR did not have an event with UID: #{uid}"
            end
            @master_event = @overridden_events.shift
          end

          @start_date = @master_event['DTSTART'].date_time(@time_zone)
          @all_day = !@master_event['DTSTART'].time?

          if @master_event.key?('EXDATE')
            @master_event['EXDATE'].each do |ex_date|
              ex_date.date_times(@time_zone).each do |dt|
                @exceptions[dt.to_i] = true
              end
            end
          end

          if @master_event.key?('DTEND')
            @event_duration = (@master_event['DTEND'].date_time(@time_zone).to_i - @start_date.to_i).seconds
          elsif @master_event.key?('DURATION')
            @event_duration = @master_event['DURATION'].date_interval
          elsif @all_day
            @event_duration = 1.day
          else
            @event_duration = 0.seconds
          end

          if @master_event.key?('RDATE')
            @recur_iterator = Recur::RDateIterator.new(
              @master_event['RDATE'].parts,
              @start_date
            )
          elsif @master_event.key?('RRULE')
            @recur_iterator = Recur::RRuleIterator.new(
              @master_event['RRULE'].parts,
              @start_date
            )
          else
            @recur_iterator = Recur::RRuleIterator.new(
              {
                'FREQ'  => 'DAILY',
                'COUNT' => 1
              },
              @start_date
            )
          end

          rewind

          unless valid
            fail Recur::NoInstancesException, 'This recurrence rule does not generate any valid instances'
          end
        end

        # Returns the date for the current position of the iterator.
        #
        # @return DateTimeImmutable
        def current
          @current_date.clone if @current_date
        end

        # This method returns the start date for the current iteration of the
        # event.
        #
        # @return DateTimeImmutable
        def dt_start
          @current_date.clone if @current_date
        end

        # This method returns the end date for the current iteration of the
        # event.
        #
        # @return DateTimeImmutable
        def dt_end
          return nil unless valid

          @current_date + @event_duration
        end

        # Returns a VEVENT for the current iterations of the event.
        #
        # This VEVENT will have a recurrence id, and it's DTSTART and DTEND
        # altered.
        #
        # @return VEvent
        def event_object
          return @current_overridden_event if @current_overridden_event

          event = @master_event.clone

          event.delete('RRULE')
          event.delete('EXDATE')
          event.delete('RDATE')
          event.delete('EXRULE')
          event.delete('RECURRENCE-ID')

          floating = event['DTSTART'].floating?
          event['DTSTART'].date_time = dt_start
          event['DTSTART'].floating = floating
          if event.key?('DTEND')
            floating = event['DTEND'].floating?
            event['DTEND'].date_time = dt_end
            event['DTEND'].floating = floating
          end

          # Including a RECURRENCE-ID to the object, unless this is the first
          # object.
          #
          # The inner recurIterator is always one step ahead, this is why we're
          # checking for the key being higher than 1.
          if @recur_iterator.key > 1
            recurid = event['DTSTART'].clone
            recurid.name = 'RECURRENCE-ID'
            event.add(recurid)
          end
          event
        end

        # Returns the current position of the iterator.
        #
        # This is for us simply a 0-based index.
        #
        # @return int
        def key
          # The counter is always 1 ahead.
          @counter - 1
        end

        # This is called after next, to see if the iterator is still at a valid
        # position, or if it's at the end.
        #
        # @return bool
        def valid
          !!@current_date
        end

        # Sets the iterator back to the starting point.
        def rewind
          @recur_iterator.rewind
          # re-creating overridden event index.
          index = {}
          @overridden_events.each_with_index do |event, key|
            stamp = event['DTSTART'].date_time(@time_zone).to_i
            index[stamp] = key
          end
          index = index.to_a.sort { |a, b| b[0] <=> a[0] }.to_h
          @counter = 0
          @overridden_events_index = index
          @current_overridden_event = nil

          @next_date = nil
          @current_date = @start_date.clone

          self.next
        end

        # Advances the iterator with one step.
        #
        # @return void
        def next
          @current_overridden_event = nil
          @counter += 1
          if @next_date
            # We had a stored value.
            next_date = @next_date
            @next_date = nil
          else
            # We need to ask rruleparser for the next date.
            # We need to do this until we find a date that's not in the
            # exception list.
            loop do
              unless @recur_iterator.valid
                next_date = nil
                break
              end
              next_date = @recur_iterator.current
              @recur_iterator.next
              break unless @exceptions.key?(next_date.to_i)
            end
          end

          # next_date now contains what rrule thinks is the next one, but an
          # overridden event may cut ahead.
          if @overridden_events_index.any?
            timestamp = @overridden_events_index.keys[-1]
            offset = @overridden_events_index[timestamp]
            if !next_date || timestamp < next_date.to_i
              # Overridden event comes first.
              @current_overridden_event = @overridden_events[offset]
              # Putting the rrule next date aside.
              @next_date = next_date
              @current_date = @current_overridden_event['DTSTART'].date_time(@time_zone)

              # Ensuring that this item will only be used once.
              @overridden_events_index.delete(timestamp)

              # Exit point!
              return nil
            end
          end

          @current_date = next_date
        end

        # Quickly jump to a date in the future.
        #
        # @param DateTimeInterface date_time
        def fast_forward(date_time)
          self.next while valid && dt_end < date_time
        end

        # Returns true if this recurring event never ends.
        #
        # @return bool
        def infinite?
          @recur_iterator.infinite?
        end

        # RRULE parser.
        #
        # @var RRuleIterator
        # RUBY: attr_accessor :recur_iterator

        # The duration, in seconds, of the master event.
        #
        # We use this to calculate the DTEND for subsequent events.
        # RUBY: attr_accessor :event_duration

        # A reference to the main (master) event.
        #
        # @var VEVENT
        # RUBY: attr_accessor :master_event

        # List of overridden events.
        #
        # @var array
        # RUBY: attr_accessor :overridden_events

        # Overridden event index.
        #
        # Key is timestamp, value is the index of the item in the overridden_event
        # property.
        #
        # @var array
        # RUBY: attr_accessor :overridden_events_index

        # A list of recurrence-id's that are either part of EXDATE, or are
        # overridden.
        #
        # @var array
        # RUBY: attr_accessor :exceptions

        # Internal event counter.
        #
        # @var int
        # RUBY: attr_accessor :counter

        # The very start of the iteration process.
        #
        # @var DateTimeImmutable
        # RUBY: attr_accessor :start_date

        # Where we are currently in the iteration process.
        #
        # @var DateTimeImmutable
        # RUBY: attr_accessor :current_date

        # The next date from the rrule parser.
        #
        # Sometimes we need to temporary store the next date, because an
        # overridden event came before.
        #
        # @var DateTimeImmutable
        # RUBY: attr_accessor :next_date

        def to_a
          fail 'Can not convert infinite event to array!' if infinite?

          list = []
          to_enum.each do |date|
            list << date
          end
          list
        end

        def each
          to_enum.each { |i| yield(i) }
        end

        def to_enum
          copy = clone
          copy.rewind
          Enumerator.new do |yielder|
            while copy.valid
              yielder << copy.dt_start
              copy.next
            end
          end
        end
      end
    end
  end
end
