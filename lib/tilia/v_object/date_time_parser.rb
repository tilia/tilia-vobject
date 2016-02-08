module Tilia
  module VObject
    # DateTimeParser.
    #
    # This class is responsible for parsing the several different date and time
    # formats iCalendar and vCards have.
    class DateTimeParser
      # Parses an iCalendar (rfc5545) formatted datetime and returns a
      # DateTimeImmutable object.
      #
      # Specifying a reference timezone is optional. It will only be used
      # if the non-UTC format is used. The argument is used as a reference, the
      # returned DateTimeImmutable object will still be in the UTC timezone.
      #
      # @param [String] dt
      # @param [ActiveSupport::TimeZone] tz
      #
      # @return [Time]
      def self.parse_date_time(dt, tz = nil)
        # Format is YYYYMMDD + "T" + hhmmss
        matches = /^([0-9]{4})([0-1][0-9])([0-3][0-9])T([0-2][0-9])([0-5][0-9])([0-5][0-9])([Z]?)$/.match(dt)

        unless matches
          fail InvalidDataException, "The supplied iCalendar datetime value is incorrect: #{dt}"
        end

        tz = ActiveSupport::TimeZone.new('UTC') if matches[7] == 'Z' || tz.nil?
        date = tz.parse("#{matches[1]}-#{matches[2]}-#{matches[3]} #{matches[4]}:#{matches[5]}:#{matches[6]}")

        date
      end

      # Parses an iCalendar (rfc5545) formatted date and returns a DateTimeImmutable object.
      #
      # @param [String] date
      # @param [ActiveSupport::TimeZone] tz
      #
      # @return [Time]
      def self.parse_date(date, tz = nil)
        # Format is YYYYMMDD
        matches = /^([0-9]{4})([0-1][0-9])([0-3][0-9])$/.match(date)

        unless matches
          fail InvalidDataException, "The supplied iCalendar date value is incorrect: #{date}"
        end

        tz = ActiveSupport::TimeZone.new('UTC') if tz.nil?

        date = tz.parse("#{matches[1]}-#{matches[2]}-#{matches[3]}")

        date
      end

      # Parses an iCalendar (RFC5545) formatted duration value.
      #
      # This method will either return a DateTimeInterval object, or a string
      # suitable for strtotime or DateTime::modify.
      #
      # @param [String] duration
      # @param [Boolean] as_string
      #
      # @return [DateInterval|string]
      def self.parse_duration(duration, as_string = false)
        matches = /^(?<plusminus>\+|-)?P((?<week>\d+)W)?((?<day>\d+)D)?(T((?<hour>\d+)H)?((?<minute>\d+)M)?((?<second>\d+)S)?)?$/.match(duration.to_s)

        unless matches
          fail InvalidDataException, "The supplied iCalendar duration value is incorrect: #{duration}"
        end

        unless as_string
          invert = false

          invert = true if matches['plusminus'] == '-'

          parts = [
            'week',
            'day',
            'hour',
            'minute',
            'second'
          ]

          new_matches = {}
          parts.each do |part|
            new_matches[part] = matches[part].to_i
          end
          matches = new_matches

          # We need to re-construct the duration string, because weeks and
          # days are not supported by DateInterval in the same string.
          duration = matches['week'].weeks +
                     matches['day'].days +
                     matches['hour'].hours +
                     matches['minute'].minutes +
                     matches['second'].seconds

          duration = -duration if invert

          return duration
        end

        parts = [
          'week',
          'day',
          'hour',
          'minute',
          'second'
        ]

        new_dur = ''

        parts.each do |part|
          new_dur += " #{matches[part]} #{part}s" if matches[part].to_i > 0
        end

        new_dur = (matches['plusminus'] == '-' ? '-' : '+') + new_dur.strip

        new_dur = '+0 seconds' if new_dur == '+'

        new_dur
      end

      # Parses either a Date or DateTime, or Duration value.
      #
      # @param [String] date
      # @param [ActiveSupport::TimeZone|string] reference_tz
      #
      # @return [DateTimeImmutable|DateInterval]
      def self.parse(date, reference_tz = nil)
        if date[0] == 'P' || (date[0] == '-' && date[1] == 'P')
          parse_duration(date)
        elsif date.length == 8
          parse_date(date, reference_tz)
        else
          parse_date_time(date, reference_tz)
        end
      end

      # This method parses a vCard date and or time value.
      #
      # This can be used for the DATE, DATE-TIME, TIMESTAMP and
      # DATE-AND-OR-TIME value.
      #
      # This method returns an array, not a DateTime value.
      #
      # The elements in the array are in the following order:
      # year, month, date, hour, minute, second, timezone
      #
      # Almost any part of the string may be omitted. It's for example legal to
      # just specify seconds, leave out the year, etc.
      #
      # Timezone is either returned as 'Z' or as '+0800'
      #
      # For any non-specified values null is returned.
      #
      # List of date formats that are supported:
      # YYYY
      # YYYY-MM
      # YYYYMMDD
      # --MMDD
      # ---DD
      #
      # YYYY-MM-DD
      # --MM-DD
      # ---DD
      #
      # List of supported time formats:
      #
      # HH
      # HHMM
      # HHMMSS
      # -MMSS
      # --SS
      #
      # HH
      # HH:MM
      # HH:MM:SS
      # -MM:SS
      # --SS
      #
      # A full basic-format date-time string looks like :
      # 20130603T133901
      #
      # A full extended-format date-time string looks like :
      # 2013-06-03T13:39:01
      #
      # Times may be postfixed by a timezone offset. This can be either 'Z' for
      # UTC, or a string like -0500 or +1100.
      #
      # @param [String] date
      #
      # @return [array]
      def self.parse_v_card_date_time(date)
        regex = /^
            (?:  # date part
                (?:
                    (?: (?<year> [0-9]{4}) (?: -)?| --)
                    (?<month> [0-9]{2})?
                |---)
                (?<date> [0-9]{2})?
            )?
            (?:T  # time part
                (?<hour> [0-9]{2} | -)
                (?<minute> [0-9]{2} | -)?
                (?<second> [0-9]{2})?

                (?: \.[0-9]{3})? # milliseconds
                (?<timezone> # timezone offset

                    Z | (?: \+|-)(?: [0-9]{4})

                )?

            )?
            $/x

        matches = regex.match(date)
        unless matches
          # Attempting to parse the extended format.
          regex = /^
              (?: # date part
                  (?: (?<year> [0-9]{4}) - | -- )
                  (?<month> [0-9]{2}) -
                  (?<date> [0-9]{2})
              )?
              (?:T # time part

                  (?: (?<hour> [0-9]{2}) : | -)
                  (?: (?<minute> [0-9]{2}) : | -)?
                  (?<second> [0-9]{2})?

                  (?: \.[0-9]{3})? # milliseconds
                  (?<timezone> # timezone offset

                      Z | (?: \+|-)(?: [0-9]{2}:[0-9]{2})

                  )?

              )?
              $/x

          matches = regex.match(date)
          unless matches
            fail InvalidDataException, "Invalid vCard date-time string: #{date}"
          end
        end

        parts = [
          'year',
          'month',
          'date',
          'hour',
          'minute',
          'second',
          'timezone'
        ]

        result = {}
        parts.each do |part|
          if matches[part].blank?
            result[part] = nil
          elsif matches[part] == '-' || matches[part] == '--'
            result[part] = nil
          else
            if part == 'timezone'
              result[part] = matches[part]
            else
              result[part] = matches[part].to_i
            end
          end
        end

        result
      end

      # This method parses a vCard TIME value.
      #
      # This method returns an array, not a DateTime value.
      #
      # The elements in the array are in the following order:
      # hour, minute, second, timezone
      #
      # Almost any part of the string may be omitted. It's for example legal to
      # just specify seconds, leave out the hour etc.
      #
      # Timezone is either returned as 'Z' or as '+08:00'
      #
      # For any non-specified values null is returned.
      #
      # List of supported time formats:
      #
      # HH
      # HHMM
      # HHMMSS
      # -MMSS
      # --SS
      #
      # HH
      # HH:MM
      # HH:MM:SS
      # -MM:SS
      # --SS
      #
      # A full basic-format time string looks like :
      # 133901
      #
      # A full extended-format time string looks like :
      # 13:39:01
      #
      # Times may be postfixed by a timezone offset. This can be either 'Z' for
      # UTC, or a string like -0500 or +11:00.
      #
      # @param [String] date
      #
      # @return [array]
      def self.parse_v_card_time(date)
        regex = /^
            (?<hour> [0-9]{2} | -)
            (?<minute> [0-9]{2} | -)?
            (?<second> [0-9]{2})?

            (?: \.[0-9]{3})? # milliseconds
            (?<timezone> # timezone offset

                Z | (?: \+|-)(?: [0-9]{4})

            )?
            $/x

        matches = regex.match(date)
        unless matches
          # Attempting to parse the extended format.
          regex = /^
              (?: (?<hour> [0-9]{2}) : | -)
              (?: (?<minute> [0-9]{2}) : | -)?
              (?<second> [0-9]{2})?

              (?: \.[0-9]{3})? # milliseconds
              (?<timezone> # timezone offset

                  Z | (?: \+|-)(?: [0-9]{2}:[0-9]{2})

              )?
              $/x

          matches = regex.match(date)
          unless matches
            fail InvalidDataException, "Invalid vCard time string: #{date}"
          end
        end

        parts = [
          'hour',
          'minute',
          'second',
          'timezone'
        ]

        result = {}
        parts.each do |part|
          if matches[part].blank?
            result[part] = nil
          elsif matches[part] == '-' || matches[part] == '--'
            result[part] = nil
          else
            result[part] = matches[part]
          end
        end

        result
      end

      # This method parses a vCard date and or time value.
      #
      # This can be used for the DATE, DATE-TIME and
      # DATE-AND-OR-TIME value.
      #
      # This method returns an array, not a DateTime value.
      # The elements in the array are in the following order:
      #     year, month, date, hour, minute, second, timezone
      # Almost any part of the string may be omitted. It's for example legal to
      # just specify seconds, leave out the year, etc.
      #
      # Timezone is either returned as 'Z' or as '+0800'
      #
      # For any non-specified values null is returned.
      #
      # List of date formats that are supported:
      #     20150128
      #     2015-01
      #     --01
      #     --0128
      #     ---28
      #
      # List of supported time formats:
      #     13
      #     1353
      #     135301
      #     -53
      #     -5301
      #     --01 (unreachable, see the tests)
      #     --01Z
      #     --01+1234
      #
      # List of supported date-time formats:
      #     20150128T13
      #     --0128T13
      #     ---28T13
      #     ---28T1353
      #     ---28T135301
      #     ---28T13Z
      #     ---28T13+1234
      #
      # See the regular expressions for all the possible patterns.
      #
      # Times may be postfixed by a timezone offset. This can be either 'Z' for
      # UTC, or a string like -0500 or +1100.
      #
      # @param [String] date
      #
      # @return [array]
      def self.parse_v_card_date_and_or_time(date)
        # \d{8}|\d{4}-\d\d|--\d\d(\d\d)?|---\d\d
        value_date     = /^(?:
                          (?<year>\d{4})(?<month>\d\d)(?<date>\d\d)
                          |(?<year0>\d{4})-(?<month0>\d\d)
                          |--(?<month1>\d\d)(?<date0>\d\d)?
                          |---(?<date1>\d\d)
                          )$/x

        # (\d\d(\d\d(\d\d)?)?|-\d\d(\d\d)?|--\d\d)(Z|[+\-]\d\d(\d\d)?)?
        value_time     = /^(?:
                          ((?<hour>\d\d)((?<minute>\d\d)(?<second>\d\d)?)?
                          |-(?<minute0>\d\d)(?<second0>\d\d)?
                          |--(?<second1>\d\d))
                          (?<timezone>(Z|[+\-]\d\d(\d\d)?))?
                          )$/x

        # (\d{8}|--\d{4}|---\d\d)T\d\d(\d\d(\d\d)?)?(Z|[+\-]\d\d(\d\d?)?
        value_date_time = /^(?:
                          ((?<year>\d{4})(?<month>\d\d)(?<date>\d\d)
                          |--(?<month0>\d\d)(?<date0>\d\d)
                          |---(?<date1>\d\d))
                          T
                          (?<hour>\d\d)((?<minute>\d\d)(?<second>\d\d)?)?
                          (?<timezone>(Z|[+\-]\d\d(\d\d?)))?
                          )$/x

        # date-and-or-time is date | date-time | time
        # in this strict order.
        matches = value_date.match(date)
        matches = value_date_time.match(date) unless matches
        matches = value_time.match(date) unless matches
        unless matches
          fail InvalidDataException, "Invalid vCard date-time string: #{date}"
        end

        map = {
          'year'     => 'year',
          'year0'    => 'year',
          'month'    => 'month',
          'month0'   => 'month',
          'month1'   => 'month',
          'date'     => 'date',
          'date0'    => 'date',
          'date1'    => 'date',
          'hour'     => 'hour',
          'minute'   => 'minute',
          'minute0'  => 'minute',
          'second'   => 'second',
          'second0'  => 'second',
          'second1'  => 'second',
          'timezone' => 'timezone'
        }

        parts = {}
        map.each do |key, real_key|
          parts[real_key] ||= nil
          parts[real_key] = matches[key] if matches.names.include?(key) && matches[key]
        end

        parts
      end
    end
  end
end
