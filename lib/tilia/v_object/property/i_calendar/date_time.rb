module Tilia
  module VObject
    class Property
      module ICalendar
        # DateTime property.
        #
        # This object represents DATE-TIME values, as defined here:
        #
        # http://tools.ietf.org/html/rfc5545#section-3.3.4
        #
        # This particular object has a bit of hackish magic that it may also in some
        # cases represent a DATE value. This is because it's a common usecase to be
        # able to change a DATE-TIME into a DATE.
        class DateTime < Property
          # In case this is a multi-value property. This string will be used as a
          # delimiter.
          #
          # @var string|null
          attr_accessor :delimiter

          # Sets a multi-valued property.
          #
          # You may also specify DateTime objects here.
          #
          # @param array parts
          #
          # @return void
          def parts=(parts)
            if parts[0].is_a?(::Time)
              self.date_times = parts
            else
              super(parts)
            end
          end

          # Updates the current value.
          #
          # This may be either a single, or multiple strings in an array.
          #
          # Instead of strings, you may also use DateTime here.
          #
          # @param string|array|DateTimeInterface value
          #
          # @return void
          def value=(value)
            if value.is_a?(Array) && value[0].is_a?(::Time)
              self.date_times = value
            elsif value.is_a?(::Time)
              self.date_times = [value]
            else
              super(value)
            end
          end

          # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
          #
          # This has been 'unfolded', so only 1 line will be passed. Unescaping is
          # not yet done, but parameters are not included.
          #
          # @param string val
          #
          # @return void
          def raw_mime_dir_value=(val)
            self.value = val.split(@delimiter)
          end

          # Returns a raw mime-dir representation of the value.
          #
          # @return string
          def raw_mime_dir_value
            parts.join(@delimiter)
          end

          # Returns true if this is a DATE-TIME value, false if it's a DATE.
          #
          # @return bool
          def time?
            self['VALUE'].to_s.upcase != 'DATE'
          end

          # Returns true if this is a floating DATE or DATE-TIME.
          #
          # Note that DATE is always floating.
          def floating?
            !self.time? || (!self.key?('TZID') && !value.index('Z'))
          end

          # Returns a date-time value.
          #
          # Note that if this property contained more than 1 date-time, only the
          # first will be returned. To get an array with multiple values, call
          # getDateTimes.
          #
          # If no timezone information is known, because it's either an all-day
          # property or floating time, we will use the DateTimeZone argument to
          # figure out the exact date.
          #
          # @param DateTimeZone time_zone
          #
          # @return DateTimeImmutable
          def date_time(time_zone = nil)
            dt = date_times(time_zone)
            return nil unless dt

            dt[0]
          end

          # Returns multiple date-time values.
          #
          # If no timezone information is known, because it's either an all-day
          # property or floating time, we will use the DateTimeZone argument to
          # figure out the exact date.
          #
          # @param DateTimeZone time_zone
          #
          # @return DateTimeImmutable[]
          # @return \DateTime[]
          def date_times(time_zone = nil)
            # Does the property have a TZID?
            tzid = self['TZID']

            time_zone = Tilia::VObject::TimeZoneUtil.time_zone(tzid.to_s, @root) if tzid

            dts = []
            parts.each do |part|
              dts << Tilia::VObject::DateTimeParser.parse(part, time_zone)
            end
            dts
          end

          # Sets the property as a DateTime object.
          #
          # @param DateTimeInterface dt
          # @param bool isFloating If set to true, timezones will be ignored.
          #
          # @return void
          def date_time=(dt)
            self.date_times = [dt]
          end

          # Sets the property as multiple date-time objects.
          #
          # The first value will be used as a reference for the timezones, and all
          # the otehr values will be adjusted for that timezone
          #
          # @param DateTimeInterface[] dt
          # @param bool isFloating If set to true, timezones will be ignored.
          #
          # @return void
          def date_times=(dt)
            update_date_times(dt)
          end

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return string
          def value_type
            time? ? 'DATE-TIME' : 'DATE'
          end

          # Returns the value, in the format it should be encoded for JSON.
          #
          # This method must always return an array.
          #
          # @return array
          def json_value
            dts = date_times

            tz = dts[0].time_zone
            is_utc = floating? ? false : ['UTC', 'GMT', 'Z'].include?(tz.name)

            dts.map do |dt|
              if time?
                dt.strftime('%Y-%m-%dT%H:%M:%S') + (is_utc ? 'Z' : '')
              else
                dt.strftime('%Y-%m-%d')
              end
            end
          end

          # Sets the json value, as it would appear in a jCard or jCal object.
          #
          # The value must always be an array.
          #
          # @param array value
          #
          # @return void
          def json_value=(value)
            # dates and times in jCal have one difference to dates and times in
            # iCalendar. In jCal date-parts are separated by dashes, and
            # time-parts are separated by colons. It makes sense to just remove
            # those.
            self.value = value.map do |item|
              item.delete(':').delete('-')
            end
          end

          # We need to intercept offsetSet, because it may be used to alter the
          # VALUE from DATE-TIME to DATE or vice-versa.
          #
          # @param string name
          # @param mixed value
          #
          # @return void
          def []=(name, value)
            super

            return nil unless name.upcase == 'VALUE'

            # This will ensure that dates are correctly encoded.
            update_date_times(date_times)
          end

          # Validates the node for correctness.
          #
          # The following options are supported:
          #   Node::REPAIR - May attempt to automatically repair the problem.
          #
          # This method returns an array with detected problems.
          # Every element has the following properties:
          #
          #  * level - problem level.
          #  * message - A human-readable string describing the issue.
          #  * node - A reference to the problematic node.
          #
          # The level means:
          #   1 - The issue was repaired (only happens if REPAIR was turned on)
          #   2 - An inconsequential issue
          #   3 - A severe issue.
          #
          # @param int options
          #
          # @return array
          def validate(options = 0)
            messages = super(options)
            value_type = self.value_type
            values = parts

            begin
              save_val = nil
              values.each do |value|
                save_val = value
                case value_type
                when 'DATE'
                  Tilia::VObject::DateTimeParser.parse_date(value)
                when 'DATE-TIME'
                  Tilia::VObject::DateTimeParser.parse_date_time(value)
                end
              end
            rescue RuntimeError
              messages << {
                'level'   => 3,
                'message' => "The supplied value (#{save_val}) is not a correct #[value_type}",
                'node'    => self
              }
            end

            messages
          end

          protected

          # Raw values of dates for post_processing
          #
          # @return [Array<TIME>]
          attr_accessor :raw_values

          public

          def initialize(*args)
            super
            @delimiter = ','
            @raw_values = []
          end

          def update_date_times(dt, is_floating = false)
            values = []

            if time?
              tz = nil
              is_utc = false

              dt.each do |d|
                if is_floating
                  values << d.strftime('%Y%m%dT%H%M%S')
                  next
                end

                if tz.nil?
                  tz = d.time_zone
                  is_utc = ['UTC', 'GMT', 'Z', '+00:00'].include?(tz.name)

                  self['TZID'] = tz.name unless is_utc
                else
                  d = d.in_time_zone(tz)
                end

                if is_utc
                  values << d.strftime('%Y%m%dT%H%M%SZ')
                else
                  values << d.strftime('%Y%m%dT%H%M%S')
                end
              end

              delete('TZID') if is_utc || is_floating
            else
              dt.each do |d|
                values << d.strftime('%Y%m%d')
              end
              delete('TZID')
            end

            @value = values
          end

          def floating
            floating?
          end

          def floating=(is_floating)
            update_date_times(date_times, is_floating)
          end
        end
      end
    end
  end
end
