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
        # @param DateTimeInterface start
        # @param DateTimeInterface ending
        #
        # @return bool
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
        # @return array
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

        # A simple list of validation rules.
        #
        # This is simply a list of properties, and how many times they either
        # must or must not appear.
        #
        # Possible values per property:
        #   * 0 - Must not appear.
        #   * 1 - Must appear exactly once.
        #   * + - Must appear at least once.
        #   * * - Can appear any number of times.
        #   * ? - May appear, but not more than once.
        #
        # @var array
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

        # Validates the node for correctness.
        #
        # The following options are supported:
        #   Node::REPAIR - May attempt to automatically repair the problem.
        #   Node::PROFILE_CARDDAV - Validate the vCard for CardDAV purposes.
        #   Node::PROFILE_CALDAV - Validate the iCalendar for CalDAV purposes.
        #
        # This method returns an array with detected problems.
        # Every element has the following properties:
        #
        #  * level - problem level.
        #  * message - A human-readable string describing the issue.
        #  * node - A reference to the problematic node.
        #
        # The level means:
        #   1 - The issue was repaired (only happens if REPAIR was turned on).
        #   2 - A warning.
        #   3 - An error.
        #
        # @param int options
        #
        # @return array
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
