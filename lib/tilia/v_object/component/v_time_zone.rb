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
        # @return [ActiveSupport::TimeZone]
        def time_zone
          Tilia::VObject::TimeZoneUtil.time_zone(self['TZID'].to_s, @root)
        end

        # (see Component#validation_rules)
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
