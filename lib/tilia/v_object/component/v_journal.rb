module Tilia
  module VObject
    class Component
      # VJournal component.
      #
      # This component contains some additional functionality specific for VJOURNALs.
      class VJournal < Component
        # Returns true or false depending on if the event falls in the specified
        # time-range. This is used for filtering purposes.
        #
        # The rules used to determine if an event falls within the specified
        # time-range is based on the CalDAV specification.
        #
        # @param [Time] start
        # @param [Time] end
        #
        # @return [Boolean]
        def in_time_range?(start, ending)
          dtstart = key?('DTSTART') ? self['DTSTART'].date_time : nil
          if dtstart
            effective_end = dtstart
            effective_end += 1.day unless self['DTSTART'].time?

            return start <= effective_end && ending > dtstart
          end

          false
        end

        # (see Component#validation_rules)
        def validation_rules
          {
            'UID'     => 1,
            'DTSTAMP' => 1,

            'CLASS'         => '?',
            'CREATED'       => '?',
            'DTSTART'       => '?',
            'LAST-MODIFIED' => '?',
            'ORGANIZER'     => '?',
            'RECURRENCE-ID' => '?',
            'SEQUENCE'      => '?',
            'STATUS'        => '?',
            'SUMMARY'       => '?',
            'URL'           => '?',

            'RRULE' => '?',

            'ATTACH'      => '*',
            'ATTENDEE'    => '*',
            'CATEGORIES'  => '*',
            'COMMENT'     => '*',
            'CONTACT'     => '*',
            'DESCRIPTION' => '*',
            'EXDATE'      => '*',
            'RELATED-TO'  => '*',
            'RDATE'       => '*'
          }
        end

        protected

        # This method should return a list of default property values.
        #
        # @return [array]
        def defaults
          {
            'UID'     => "tilia-vobject-#{UuidUtil.uuid}",
            'DTSTAMP' => Time.zone.now.strftime('%Y%m%dT%H%M%SZ')
          }
        end
      end
    end
  end
end
