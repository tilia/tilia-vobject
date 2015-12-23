module Tilia
  module VObject
    # This class helps with generating FREEBUSY reports based on existing sets of
    # objects.
    #
    # It only looks at VEVENT and VFREEBUSY objects from the sourcedata, and
    # generates a single VFREEBUSY object.
    #
    # VFREEBUSY components are described in RFC5545, The rules for what should
    # go in a single freebusy report is taken from RFC4791, section 7.10.
    class FreeBusyGenerator
      # Input objects.
      #
      # @var array
      # RUBY: attr_accessor :objects

      # Start of range.
      #
      # @var DateTimeInterface|null
      # RUBY: attr_accessor :start

      # End of range.
      #
      # @var DateTimeInterface|null
      # RUBY: attr_accessor :end

      # VCALENDAR object.
      #
      # @var Document
      # RUBY: attr_accessor :base_object

      # Reference timezone.
      #
      # When we are calculating busy times, and we come across so-called
      # floating times (times without a timezone), we use the reference timezone
      # instead.
      #
      # This is also used for all-day events.
      #
      # This defaults to UTC.
      #
      # @var DateTimeZone
      # RUBY: attr_accessor :time_zone

      # A VAVAILABILITY document.
      #
      # If this is set, it's information will be included when calculating
      # freebusy time.
      #
      # @var Document
      # RUBY: attr_accessor :vavailability

      # Creates the generator.
      #
      # Check the setTimeRange and setObjects methods for details about the
      # arguments.
      #
      # @param DateTimeInterface start
      # @param DateTimeInterface end
      # @param mixed objects
      # @param DateTimeZone time_zone
      def initialize(start = nil, ending = nil, objects = nil, time_zone = nil)
        start = Time.zone.parse(Settings.min_date) unless start
        ending = Time.zone.parse(Settings.max_date) unless ending

        self.time_range = start..ending
        @objects = []

        self.objects = objects if objects
        time_zone = ActiveSupport::TimeZone.new('UTC') unless time_zone
        self.time_zone = time_zone
      end

      # Sets the VCALENDAR object.
      #
      # If this is set, it will not be generated for you. You are responsible
      # for setting things like the METHOD, CALSCALE, VERSION, etc..
      #
      # The VFREEBUSY object will be automatically added though.
      #
      # @param Document vcalendar
      # @return void
      attr_writer :base_object

      # Sets a VAVAILABILITY document.
      #
      # @param Document vcalendar
      # @return void
      def v_availability=(vcalendar)
        @vavailability = vcalendar
      end

      # Sets the input objects.
      #
      # You must either specify a valendar object as a string, or as the parse
      # Component.
      # It's also possible to specify multiple objects as an array.
      #
      # @param mixed objects
      #
      # @return void
      def objects=(objects)
        objects = [objects] unless objects.is_a?(Array)

        @objects = []
        objects.each do |object|
          if object.is_a?(String)
            @objects << Reader.read(object)
          elsif object.is_a?(Component)
            @objects << object
          else
            fail ArgumentError, 'You can only pass strings or Component arguments to setObjects'
          end
        end
      end

      # Sets the time range.
      #
      # Any freebusy object falling outside of this time range will be ignored.
      #
      # @param DateTimeInterface start
      # @param DateTimeInterface end
      #
      # @return void
      def time_range=(range)
        @start = range.begin
        @end = range.end
      end

      # Sets the reference timezone for floating times.
      #
      # @param DateTimeZone time_zone
      #
      # @return void
      def time_zone=(time_zone)
        @time_zone = time_zone
      end

      # Parses the input data and returns a correct VFREEBUSY object, wrapped in
      # a VCALENDAR.
      #
      # @return Component
      def result
        fb_data = FreeBusyData.new(@start.to_i, @end.to_i)

        calculate_availability(fb_data, @vavailability) if @vavailability

        calculate_busy(fb_data, @objects)
        generate_free_busy_calendar(fb_data)
      end

      protected

      # This method takes a VAVAILABILITY component and figures out all the
      # available times.
      #
      # @param FreeBusyData fb_data
      # @param VCalendar vavailability
      # @return void
      def calculate_availability(fb_data, vavailability)
        vavail_comps = vavailability['VAVAILABILITY'].to_a
        vavail_comps.sort! do |a, b|
          # We need to order the components by priority. Priority 1
          # comes first, up until priority 9. Priority 0 comes after
          # priority 9. No priority implies priority 0.
          #
          # Yes, I'm serious.
          priority_a = a.key?('PRIORITY') ? a['PRIORITY'].value.to_i : 0
          priority_b = b.key?('PRIORITY') ? b['PRIORITY'].value.to_i : 0

          priority_a = 10 if priority_a == 0
          priority_b = 10 if priority_b == 0

          priority_a <=> priority_b
        end

        # Now we go over all the VAVAILABILITY components and figure if
        # there's any we don't need to consider.
        #
        # This is can be because of one of two reasons: either the
        # VAVAILABILITY component falls outside the time we are interested in,
        # or a different VAVAILABILITY component with a higher priority has
        # already completely covered the time-range.
        old = vavail_comps
        new = []

        old.each do |vavail|
          (comp_start, comp_end) = vavail.effective_start_end

          # We don't care about datetimes that are earlier or later than the
          # start and end of the freebusy report, so this gets normalized
          # first.
          comp_start = @start if comp_start.nil? || comp_start < @start
          comp_end = @end if comp_end.nil? || comp_end > @end

          # If the item fell out of the timerange, we can just skip it.
          next if comp_start > @end || comp_end < @start

          # Going through our existing list of components to see if there's
          # a higher priority component that already fully covers this one.
          skip = false
          new.each do |higher_vavail|
            (higher_start, higher_end) = higher_vavail.effective_start_end
            if (higher_start.nil? || higher_start < comp_start) &&
               (higher_end.nil? || higher_end > comp_end)
              # Component is fully covered by a higher priority
              # component. We can skip this component.
              skip = true
              break
            end
          end
          next if skip

          # We're keeping it!
          new << vavail
        end

        # Lastly, we need to traverse the remaining components and fill in the
        # freebusydata slots.
        #
        # We traverse the components in reverse, because we want the higher
        # priority components to override the lower ones.
        new.reverse_each do |vavail|
          busy_type = vavail.key?('BUSYTYPE') ? vavail['BUSYTYPE'].to_s.upcase : 'BUSY-UNAVAILABLE'
          (vavail_start, vavail_end) = vavail.effective_start_end

          # Making the component size no larger than the requested free-busy
          # report range.
          vavail_start = @start if !vavail_start || vavail_start < @start
          vavail_end = @end if !vavail_end || vavail_end > @end

          # Marking the entire time range of the VAVAILABILITY component as
          # busy.
          fb_data.add(
            vavail_start.to_i,
            vavail_end.to_i,
            busy_type
          )

          # Looping over the AVAILABLE components.
          if vavail.key?('AVAILABLE')
            vavail['AVAILABLE'].each do |available|
              (avail_start, avail_end) = available.effective_start_end
              fb_data.add(
                avail_start.to_i,
                avail_end.to_i,
                'FREE'
              )

              if available['RRULE']
                # Our favourite thing: recurrence!!
                rrule_iterator = Recur::RRuleIterator.new(
                  available['RRULE'].value,
                  avail_start
                )

                rrule_iterator.fast_forward(vavail_start)

                start_end_diff = avail_end - avail_start

                while rrule_iterator.valid
                  recur_start = rrule_iterator.current
                  recur_end = recur_start + start_end_diff

                  if recur_start > vavail_end
                    # We're beyond the legal timerange.
                    break
                  end

                  if recur_end > vavail_end
                    # Truncating the end if it exceeds the
                    # VAVAILABILITY end.
                    recur_end = vavail_end
                  end

                  fb_data.add(
                    recur_start.to_i,
                    recur_end.to_i,
                    'FREE'
                  )

                  rrule_iterator.next
                end
              end
            end
          end
        end
      end

      # This method takes an array of iCalendar objects and applies its busy
      # times on fbData.
      #
      # @param FreeBusyData fb_data
      # @param VCalendar[] objects
      def calculate_busy(fb_data, objects)
        objects.each_with_index do |object, key|
          object.base_components.each do |component|
            case component.name
            when 'VEVENT'
              skip = false
              fb_type = 'BUSY'
              if component.key?('TRANSP') && component['TRANSP'].to_s.upcase == 'TRANSPARENT'
                skip = true
              end
              if component.key?('STATUS')
                status = component['STATUS'].to_s.upcase
                if status == 'CANCELLED'
                  skip = true
                elsif status == 'TENTATIVE'
                  fb_type = 'BUSY-TENTATIVE'
                end
              end

              unless skip
                times = []

                if component.key?('RRULE')
                  begin
                    iterator = Recur::EventIterator.new(object, component['UID'].to_s, @time_zone)
                  rescue Recur::NoInstancesException => e
                    # This event is recurring, but it doesn't have a single
                    # instance. We are skipping this event from the output
                    # entirely.
                    @objects.delete_at(key)
                    next
                  end

                  iterator.fast_forward(@start) if @start

                  max_recurrences = 200

                  while iterator.valid && max_recurrences > 0
                    max_recurrences -= 1

                    start_time = iterator.dt_start
                    break if @end && start_time > @end
                    times << [
                      iterator.dt_start,
                      iterator.dt_end
                    ]

                    iterator.next
                  end
                else
                  start_time = component['DTSTART'].date_time(@time_zone)
                  skip = true if @end && start_time > @end

                  end_time = nil
                  if component.key?('DTEND')
                    end_time = component['DTEND'].date_time(@time_zone)
                  elsif component.key?('DURATION')
                    duration = DateTimeParser.parse_duration(component['DURATION'].to_s)
                    end_time = start_time + duration
                  elsif !component['DTSTART'].time?
                    end_time = start_time + 1.day
                  else
                    # The event had no duration (0 seconds)
                    skip = true
                  end

                  times << [start_time, end_time] unless skip
                end

                times.each do |time|
                  break if @end && time[0] > @end
                  break if @start && time[1] < @start

                  fb_data.add(
                    time[0].to_i,
                    time[1].to_i,
                    fb_type
                  )
                end
              end
            when 'VFREEBUSY'
              component['FREEBUSY'].each do |freebusy|
                fb_type = freebusy.key?('FBTYPE') ? freebusy['FBTYPE'].to_s.upcase : 'BUSY'

                # Skipping intervals marked as 'free'
                next if fb_type == 'FREE'

                values = freebusy.to_s.split(',')
                values.each do |value|
                  (start_time, end_time) = value.split('/')
                  start_time = DateTimeParser.parse_date_time(start_time)

                  if end_time[0] == 'P' || end_time[0..1] == '-P'
                    duration = DateTimeParser.parse_duration(end_time)
                    end_time = start_time + duration
                  else
                    end_time = DateTimeParser.parse_date_time(end_time)
                  end

                  next if @start && @start > end_time
                  next if @end && @end < start_time

                  fb_data.add(
                    start_time.to_i,
                    end_time.to_i,
                    fb_type
                  )
                end
              end
            end
          end
        end
      end

      # This method takes a FreeBusyData object and generates the VCALENDAR
      # object associated with it.
      #
      # @return VCalendar
      def generate_free_busy_calendar(fb_data)
        if @base_object
          calendar = @base_object
        else
          calendar = Component::VCalendar.new
        end

        vfreebusy = calendar.create_component('VFREEBUSY')
        calendar.add(vfreebusy)

        if @start
          dtstart = calendar.create_property('DTSTART')
          dtstart.date_time = @start
          vfreebusy.add(dtstart)
        end
        if @end
          dtend = calendar.create_property('DTEND')
          dtend.date_time = @end
          vfreebusy.add(dtend)
        end

        tz = ActiveSupport::TimeZone.new('UTC')
        dtstamp = calendar.create_property('DTSTAMP')
        dtstamp.date_time = tz.now
        vfreebusy.add(dtstamp)

        fb_data.data.each do |busy_time|
          busy_type = busy_time['type'].upcase

          # Ignoring all the FREE parts, because those are already assumed.
          next if busy_type == 'FREE'

          tmp = []
          tmp << tz.at(busy_time['start'])
          tmp << tz.at(busy_time['end'])

          prop = calendar.create_property(
            'FREEBUSY',
            tmp[0].strftime('%Y%m%dT%H%M%SZ') + '/' + tmp[1].strftime('%Y%m%dT%H%M%SZ')
          )

          # Only setting FBTYPE if it's not BUSY, because BUSY is the
          # default anyway.
          prop['FBTYPE'] = busy_type unless busy_type == 'BUSY'

          vfreebusy.add(prop)
        end

        calendar
      end
    end
  end
end
