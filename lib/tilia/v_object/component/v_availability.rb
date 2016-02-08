module Tilia
  module VObject
    class Component
      # The VAvailability component.
      #
      # This component adds functionality to a component, specific for VAVAILABILITY
      # components.
      class VAvailability < Component
        # Returns true or false depending on if the event falls in the specified
        # time-range. This is used for filtering purposes.
        #
        # The rules used to determine if an event falls within the specified
        # time-range is based on:
        #
        # https://tools.ietf.org/html/draft-daboo-calendar-availability-05#section-3.1
        #
        # @param [Time] start
        # @param [Time] ending
        #
        # @return [Boolean]
        def in_time_range?(start, ending)
          (effective_start, effective_end) = effective_start_end
          (effective_start.nil? || start < effective_end) &&
            (effective_end.nil? || ending > effective_start)
        end

        # Returns the 'effective start' and 'effective end' of this VAVAILABILITY
        # component.
        #
        # We use the DTSTART and DTEND or DURATION to determine this.
        #
        # The returned value is an array containing DateTimeImmutable instances.
        # If either the start or end is 'unbounded' its value will be null
        # instead.
        #
        # @return [Array<Time, nil>]
        def effective_start_end
          effective_start = nil
          effective_end = nil

          effective_start = self['DTSTART'].date_time if key?('DTSTART')

          if key?('DTEND')
            effective_end = self['DTEND'].date_time
          elsif effective_start && key?('DURATION')
            effective_end = effective_start + Tilia::VObject::DateTimeParser.parse_duration(self['DURATION'])
          end

          [effective_start, effective_end]
        end

        # (see Component#validation_rules)
        def validation_rules
          {
            'UID'     => 1,
            'DTSTAMP' => 1,

            'BUSYTYPE'      => '?',
            'CLASS'         => '?',
            'CREATED'       => '?',
            'DESCRIPTION'   => '?',
            'DTSTART'       => '?',
            'LAST-MODIFIED' => '?',
            'ORGANIZER'     => '?',
            'PRIORITY'      => '?',
            'SEQUENCE'      => '?',
            'SUMMARY'       => '?',
            'URL'           => '?',
            'DTEND'         => '?',
            'DURATION'      => '?',

            'CATEGORIES' => '*',
            'COMMENT'    => '*',
            'CONTACT'    => '*'
          }
        end

        # (see Component#validate)
        def validate(options = 0)
          result = super(options)

          if key?('DTEND') && key?('DURATION')
            result << {
              'level'   => 3,
              'message' => 'DTEND and DURATION cannot both be present',
              'node'    => self
            }
          end

          result
        end
      end
    end
  end
end
