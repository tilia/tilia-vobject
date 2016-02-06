module Tilia
  module VObject
    class Component
      # VTodo component.
      #
      # This component contains some additional functionality specific for VTODOs.
      class VTodo < Component
        # Returns true or false depending on if the event falls in the specified
        # time-range. This is used for filtering purposes.
        #
        # The rules used to determine if an event falls within the specified
        # time-range is based on the CalDAV specification.
        #
        # @param DateTimeInterface start
        # @param DateTimeInterface end
        #
        # @return bool
        def in_time_range?(start, ending)
          dtstart = key?('DTSTART') ? self['DTSTART'].date_time : nil
          duration = key?('DURATION') ? Tilia::VObject::DateTimeParser.parse_duration(self['DURATION']) : nil
          due = key?('DUE') ? self['DUE'].date_time : nil
          completed = key?('COMPLETED') ? self['COMPLETED'].date_time : nil
          created = key?('CREATED') ? self['CREATED'].date_time : nil

          if dtstart
            if duration
              effective_ending = dtstart + duration
              return start <= effective_ending && ending > dtstart
            elsif due
              return (start < due || start <= dtstart) && (ending > dtstart || ending >= due)
            else
              return start <= dtstart && ending > dtstart
            end
          end

          return start < due && ending >= due if due

          if completed && created
            return (start <= created || start <= completed) && (ending >= created || ending >= completed)
          end

          return (start <= completed && ending >= completed) if completed

          return (ending > created) if created

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

            'CLASS'         => '?',
            'COMPLETED'     => '?',
            'CREATED'       => '?',
            'DESCRIPTION'   => '?',
            'DTSTART'       => '?',
            'GEO'           => '?',
            'LAST-MODIFIED' => '?',
            'LOCATION'      => '?',
            'ORGANIZER'     => '?',
            'PERCENT'       => '?',
            'PRIORITY'      => '?',
            'RECURRENCE-ID' => '?',
            'SEQUENCE'      => '?',
            'STATUS'        => '?',
            'SUMMARY'       => '?',
            'URL'           => '?',

            'RRULE'    => '?',
            'DUE'      => '?',
            'DURATION' => '?',

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
          result = super(options)
          if key?('DUE') && key?('DTSTART')
            due = self['DUE']
            dt_start = self['DTSTART']

            if due.value_type != dt_start.value_type
              result << {
                'level'   => 3,
                'message' => 'The value type (DATE or DATE-TIME) must be identical for DUE and DTSTART',
                'node'    => due
              }
            elsif due.date_time < dt_start.date_time
              result << {
                'level'   => 3,
                'message' => 'DUE must occur after DTSTART',
                'node'    => due
              }
            end
          end

          result
        end

        protected

        # This method should return a list of default property values.
        #
        # @return array
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
