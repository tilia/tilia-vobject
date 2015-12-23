module Tilia
  module VObject
    class Component
      # The VTimeZone component.
      #
      # This component adds functionality to a component, specific for VTIMEZONE
      # components.
      class VTimeZone < Component
        # Returns the PHP DateTimeZone for this VTIMEZONE component.
        #
        # If we can't accurately determine the timezone, this method will return
        # UTC.
        #
        # @return \DateTimeZone
        def time_zone
          Tilia::VObject::TimeZoneUtil.time_zone(self['TZID'].to_s, @root)
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
            'TZID' => 1,

            'LAST-MODIFIED' => '?',
            'TZURL'         => '?',

            # At least 1 STANDARD or DAYLIGHT must appear, or more. But both
            # cannot appear in the same VTIMEZONE.
            #
            # The validator is not specific yet to pick this up, so these
            # rules are too loose.
            'STANDARD' => '*',
            'DAYLIGHT' => '*'
          }
        end
      end
    end
  end
end
