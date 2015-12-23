module Tilia
  module VObject
    class Component
      # The VFreeBusy component.
      #
      # This component adds functionality to a component, specific for VFREEBUSY
      # components.
      class VFreeBusy < Component
        # Checks based on the contained FREEBUSY information, if a timeslot is
        # available.
        #
        # @param DateTimeInterface start
        # @param DateTimeInterface end
        #
        # @return bool
        def free?(start, ending)
          select('FREEBUSY').each do |freebusy|
            # We are only interested in FBTYPE=BUSY (the default),
            # FBTYPE=BUSY-TENTATIVE or FBTYPE=BUSY-UNAVAILABLE.
            if freebusy.key?('FBTYPE') && freebusy['FBTYPE'].to_s[0...4].upcase != 'BUSY'
              next
            end

            # The freebusy component can hold more than 1 value, separated by
            # commas.
            periods = freebusy.to_s.split(/,/)

            periods.each do |period|
              # Every period is formatted as [start]/[end]. The start is an
              # absolute UTC time, the end may be an absolute UTC time, or
              # duration (relative) value.
              (busy_start, busy_end) = period.split('/')

              busy_start = Tilia::VObject::DateTimeParser.parse(busy_start)
              busy_end = Tilia::VObject::DateTimeParser.parse(busy_end)

              if busy_end.is_a?(ActiveSupport::Duration)
                busy_end = busy_start + busy_end
              end

              return false if start < busy_end && ending > busy_start
            end
          end

          true
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

            'CONTACT'   => '?',
            'DTSTART'   => '?',
            'DTEND'     => '?',
            'ORGANIZER' => '?',
            'URL'       => '?',

            'ATTENDEE'       => '*',
            'COMMENT'        => '*',
            'FREEBUSY'       => '*',
            'REQUEST-STATUS' => '*'
          }
        end
      end
    end
  end
end
