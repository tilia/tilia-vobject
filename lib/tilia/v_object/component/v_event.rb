module Tilia
  module VObject
    class Component
      # VEvent component.
      #
      # This component contains some additional functionality specific for VEVENT's.
      class VEvent < Component
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
          if self['RRULE']
            begin
              it = Tilia::VObject::Recur::EventIterator.new(self, nil, start.time_zone)
            rescue Tilia::VObject::Recur::NoInstancesException
              # If we've catched this exception, there are no instances
              # for the event that fall into the specified time-range.
              return false
            end

            it.fast_forward(start)

            # We fast-forwarded to a spot where the end-time of the
            # recurrence instance exceeded the start of the requested
            # time-range.
            #
            # If the starttime of the recurrence did not exceed the
            # end of the time range as well, we have a match.
            return false unless it.dt_start
            return (it.dt_start < ending && it.dt_end > start)
          end

          effective_start = self['DTSTART'].date_time(start.time_zone)
          if self.key?('DTEND')

            # The DTEND property is considered non inclusive. So for a 3 day
            # event in july, dtstart and dtend would have to be July 1st and
            # July 4th respectively.
            #
            # See:
            # http://tools.ietf.org/html/rfc5545#page-54
            effective_end = self['DTEND'].date_time(ending.time_zone)

          elsif self.key?('DURATION')
            effective_end = effective_start + Tilia::VObject::DateTimeParser.parse_duration(self['DURATION'])
          elsif !self['DTSTART'].time?
            effective_end = effective_start + 1.day
          else
            effective_end = effective_start
          end

          start < effective_end && ending > effective_start
        end

        protected

        # This method should return a list of default property values.
        #
        # @return [Hash]
        def defaults
          {
            'UID'     => 'sabre-vobject-' + Tilia::VObject::UuidUtil.uuid,
            'DTSTAMP' => Time.zone.now.utc.strftime('%Y%m%dT%H%M%SZ')
          }
        end

        public

        # (see Component#validation_rules)
        def validation_rules
          {
            'UID'           => 1,
            'DTSTAMP'       => 1,
            'DTSTART'       => parent.key?('METHOD') ? '?' : '1',
            'CLASS'         => '?',
            'CREATED'       => '?',
            'DESCRIPTION'   => '?',
            'GEO'           => '?',
            'LAST-MODIFIED' => '?',
            'LOCATION'      => '?',
            'ORGANIZER'     => '?',
            'PRIORITY'      => '?',
            'SEQUENCE'      => '?',
            'STATUS'        => '?',
            'SUMMARY'       => '?',
            'TRANSP'        => '?',
            'URL'           => '?',
            'RECURRENCE-ID' => '?',
            'RRULE'         => '?',
            'DTEND'         => '?',
            'DURATION'      => '?',

            'ATTACH'         => '*',
            'ATTENDEE'       => '*',
            'CATEGORIES'     => '*',
            'COMMENT'        => '*',
            'CONTACT'        => '*',
            'EXDATE'         => '*',
            'REQUEST-STATUS' => '*',
            'RELATED-TO'     => '*',
            'RESOURCES'      => '*',
            'RDATE'          => '*'
          }
        end
      end
    end
  end
end
