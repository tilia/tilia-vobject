module Tilia
  module VObject
    class Component
      # The Available sub-component.
      #
      # This component adds functionality to a component, specific for AVAILABLE
      # components.
      class Available < Component
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
          effective_start = self['DTSTART'].date_time
          if key?('DTEND')
            effective_end = self['DTEND'].date_time
          else
            effective_end = effective_start + DateTimeParser.parse_duration(self['DURATION'])
          end

          [effective_start, effective_end]
        end

        # (see Component#validation_rules)
        def validation_rules
          {
            'UID'     => 1,
            'DTSTART' => 1,
            'DTSTAMP' => 1,

            'DTEND'    => '?',
            'DURATION' => '?',

            'CREATED'       => '?',
            'DESCRIPTION'   => '?',
            'LAST-MODIFIED' => '?',
            'RECURRENCE-ID' => '?',
            'RRULE'         => '?',
            'SUMMARY'       => '?',

            'CATEGORIES' => '*',
            'COMMENT'    => '*',
            'CONTACT'    => '*',
            'EXDATE'     => '*',
            'RDATE'      => '*',

            'AVAILABLE' => '*'
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
