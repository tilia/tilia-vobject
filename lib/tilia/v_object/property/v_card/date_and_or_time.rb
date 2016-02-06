module Tilia
  module VObject
    class Property
      module VCard
        # DateAndOrTime property.
        #
        # This object encodes DATE-AND-OR-TIME values.
        class DateAndOrTime < Property
          # Field separator.
          #
          # @var null|string
          attr_accessor :delimiter

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return string
          def value_type
            'DATE-AND-OR-TIME'
          end

          # Sets a multi-valued property.
          #
          # You may also specify DateTime objects here.
          #
          # @param array parts
          #
          # @return void
          def parts=(parts)
            fail ArgumentError, 'Only one value allowed' if parts.size > 1

            if parts[0].is_a?(::Time)
              self.date_time = parts[0]
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
          # @param string|array|\DateTime value
          #
          # @return void
          def value=(value)
            if value.is_a?(::Time)
              self.date_time = value
            else
              super
            end
          end

          # Sets the property as a DateTime object.
          #
          # @param DateTimeInterface dt
          #
          # @return void
          def date_time=(dt)
            tz = dt.time_zone
            is_utc = ['UTC', 'GMT', 'Z'].include?(tz.name)

            if is_utc
              value = dt.strftime('%Y%m%dT%H%M%SZ')
            else
              # Calculating the offset.
              value = dt.strftime('%Y%m%dT%H%M%S%z')
            end

            @value = value
          end

          # Returns a date-time value.
          #
          # Note that if this property contained more than 1 date-time, only the
          # first will be returned. To get an array with multiple values, call
          # getDateTimes.
          #
          # If no time was specified, we will always use midnight (in the default
          # timezone) as the time.
          #
          # If parts of the date were omitted, such as the year, we will grab the
          # current values for those. So at the time of writing, if the year was
          # omitted, we would have filled in 2014.
          #
          # @return DateTimeImmutable
          def date_time
            now = ::Time.zone.now

            tz_format = now.utc_offset == 0 ? 'Z' : '%z'
            now_parts = DateTimeParser.parse_v_card_date_time(now.strftime('%Y%m%dT%H%M%S' + tz_format))
            date_parts = DateTimeParser.parse_v_card_date_time(value)

            # This sets all the missing parts to the current date/time.
            # So if the year was missing for a birthday, we're making it 'this
            # year'.
            date_parts.each do |k, v|
              date_parts[k] = now_parts[k] unless v
            end

            # Now follows a ruby Hack
            offset = "#{date_parts['timezone'][0]}1".to_i * ( date_parts['timezone'][1..2].to_i * 3600 + date_parts['timezone'][3..4].to_i * 60)
            tz = ActiveSupport::TimeZone.new(offset)
            datetime = tz.parse("#{date_parts['year']}-#{date_parts['month']}-#{date_parts['date']} #{date_parts['hour']}:#{date_parts['minute']}:#{date_parts['second']}")
            if datetime.dst?
              tz = ActiveSupport::TimeZone.new(offset - 3600)
              datetime = tz.parse("#{date_parts['year']}-#{date_parts['month']}-#{date_parts['date']} #{date_parts['hour']}:#{date_parts['minute']}:#{date_parts['second']}")
            end
            # continue as usual

            datetime.freeze
            datetime
          end

          # Returns the value, in the format it should be encoded for json.
          #
          # This method must always return an array.
          #
          # @return array
          def json_value
            parts = DateTimeParser.parse_v_card_date_time(value)

            date_str = ''

            # Year
            if !parts['year'].nil?
              date_str += format('%02i', parts['year'])

              unless parts['month'].nil?
                # If a year and a month is set, we need to insert a separator
                # dash.
                date_str += '-'
              end
            else
              if !parts['month'].nil? || !parts['date'].nil?
                # Inserting two dashes
                date_str += '--'
              end
            end

            # Month
            if !parts['month'].nil?
              date_str += format('%02i', parts['month'])

              if parts['date']
                # If month and date are set, we need the separator dash.
                date_str += '-'
              end
            elsif parts['date']
              # If the month is empty, and a date is set, we need a 'empty
              # dash'
              date_str += '-'
            end

            # Date
            date_str += format('%02i', parts['date']) unless parts['date'].nil?

            # Early exit if we don't have a time string.
            if parts['hour'].nil? && parts['minute'].nil? && parts['second'].nil?
              return [date_str]
            end

            date_str += 'T'

            # Hour
            if !parts['hour'].nil?
              date_str += format('%02i', parts['hour'])

              date_str += ':' unless parts['minute'].nil?
            else
              # We know either minute or second _must_ be set, so we insert a
              # dash for an empty value.
              date_str += '-'
            end

            # Minute
            if !parts['minute'].nil?
              date_str += format('%02i', parts['minute'])

              date_str += ':' unless parts['second'].nil?
            elsif parts['second']
              # Dash for empty minute
              date_str += '-'
            end

            # Second
            date_str += format('%02i', parts['second']) unless parts['second'].nil?

            # Timezone
            date_str += parts['timezone'] unless parts['timezone'].nil?

            [date_str]
          end

          protected

          # This method serializes only the value of a property. This is used to
          # create xCard or xCal documents.
          #
          # @param Xml\Writer writer  XML writer.
          #
          # @return void
          def xml_serialize_value(writer)
            value_type = self.value_type.downcase
            parts     = DateTimeParser.parse_v_card_date_and_or_time(value)
            value     = ''

            # d = defined
            d = lambda do |part|
              !parts[part].nil?
            end

            # r = read
            r = lambda do |part|
              parts[part] || ''
            end

            # From the Relax NG Schema.
            #
            # # 4.3.1
            # value-date = element date {
            #     xsd:string { pattern = "\d{8}|\d{4}-\d\d|--\d\d(\d\d)?|---\d\d" }
            #   }
            if (d.call('year') || d.call('month') || d.call('date')) && (!d.call('hour') && !d.call('minute') && !d.call('second') && !d.call('timezone'))
              if d.call('year') && d.call('month') && d.call('date')
                value += r.call('year') + r.call('month') + r.call('date')
              elsif d.call('year') && d.call('month') && !d.call('date')
                value += r.call('year') + '-' + r.call('month')
              elsif !d.call('year') && d.call('month')
                value += '--' + r.call('month') + r.call('date')
              elsif !d.call('year') && !d.call('month') && d.call('date')
                value += '---' + r.call('date')
              end

            # # 4.3.2
            # value-time = element time {
            #     xsd:string { pattern = "(\d\d.call(\d\d.call(\d\d)?)?|-\d\d.call(\d\d?)|--\d\d)"
            #                          ~ "(Z|[+\-]\d\d.call(\d\d)?)?" }
            #   }
            elsif (!d.call('year') && !d.call('month') && !d.call('date')) && (d.call('hour') || d.call('minute') || d.call('second'))
              if d.call('hour')
                value += r.call('hour') + r.call('minute') + r.call('second')
              elsif d.call('minute')
                value += '-' + r.call('minute') + r.call('second')
              elsif d.call('second')
                value += '--' + r.call('second')
              end

              value += r.call('timezone')

            # # 4.3.3
            # value-date-time = element date-time {
            #     xsd:string { pattern = "(\d{8}|--\d{4}|---\d\d)T\d\d.call(\d\d.call(\d\d)?)?"
            #                          ~ "(Z|[+\-]\d\d.call(\d\d)?)?" }
            #   }
            elsif d.call('date') && d.call('hour')

              if d.call('year') && d.call('month') && d.call('date')
                value += r.call('year') + r.call('month') + r.call('date')
              elsif !d.call('year') && d.call('month') && d.call('date')
                value += '--' + r.call('month') + r.call('date')
              elsif !d.call('year') && !d.call('month') && d.call('date')
                value += '---' + r.call('date')
              end

              value += 'T' + r.call('hour') + r.call('minute') + r.call('second') +
                       r.call('timezone')
            end

            writer.write_element(value_type, value)
          end

          public

          # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
          #
          # This has been 'unfolded', so only 1 line will be passed. Unescaping is
          # not yet done, but parameters are not included.
          #
          # @param string val
          #
          # @return void
          def raw_mime_dir_value=(val)
            self.value = val
          end

          # Returns a raw mime-dir representation of the value.
          #
          # @return string
          def raw_mime_dir_value
            parts.join(@delimiter)
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
            value = self.value

            begin
              DateTimeParser.parse_v_card_date_time(value)
            rescue InvalidDataException
              messages << {
                'level'   => 3,
                'message' => "The supplied value (#{value}) is not a correct DATE-AND-OR-TIME property",
                'node'    => self
              }
            end

            messages
          end

          def initialize(*args)
            super(*args)
            @delimiter = nil
          end
        end
      end
    end
  end
end
