module Tilia
  module VObject
    class Component
      # VAlarm component.
      #
      # This component contains some additional functionality specific for VALARMs.
      class VAlarm < Component
        # Returns a DateTime object when this alarm is going to trigger.
        #
        # This ignores repeated alarm, only the first trigger is returned.
        #
        # @return DateTimeImmutable
        def effective_trigger_time
          trigger = self['TRIGGER']
          if !trigger.key?('VALUE') || trigger['VALUE'].to_s.upcase == 'DURATION'
            trigger_duration = DateTimeParser.parse_duration(self['TRIGGER'])
            related = (trigger.key?('RELATED') && trigger['RELATED'].to_s.upcase == 'END') ? 'END' : 'START'

            parent_component = parent
            if related == 'START'
              if parent_component.name == 'VTODO'
                prop_name = 'DUE'
              else
                prop_name = 'DTSTART'
              end

              effective_trigger = parent_component[prop_name].date_time
              effective_trigger += trigger_duration
            else
              if parent_component.name == 'VTODO'
                end_prop = 'DUE'
              elsif parent_component.name == 'VEVENT'
                end_prop = 'DTEND'
              else
                fail 'time-range filters on VALARM components are only supported when they are a child of VTODO or VEVENT'
              end

              if parent_component.key?(end_prop)
                effective_trigger = parent_component[end_prop].date_time
                effective_trigger += trigger_duration
              elsif parent_component.key?('DURATION')
                effective_trigger = parent_component['DTSTART'].date_time
                duration = DateTimeParser.parse_duration(parent_component['DURATION'])
                effective_trigger += duration
                effective_trigger += trigger_duration
              else
                effective_trigger = parent_component['DTSTART'].date_time
                effective_trigger += trigger_duration
              end
            end
          else
            effective_trigger = trigger.date_time
          end

          effective_trigger
        end

        # Returns true or false depending on if the event falls in the specified
        # time-range. This is used for filtering purposes.
        #
        # The rules used to determine if an event falls within the specified
        # time-range is based on the CalDAV specification.
        #
        # @param DateTime start
        # @param DateTime ending
        #
        # @return bool
        def in_time_range?(start, ending)
          effective_trigger = effective_trigger_time

          if key?('DURATION')
            duration = DateTimeParser.parse_duration(self['DURATION'])
            repeat = self['REPEAT'].to_s.to_i
            repeat = 1 if repeat == 0

            occurrence = effective_trigger
            return true if start <= occurrence && ending > occurrence

            repeat.times do |_i|
              occurrence += duration
              return true if start <= occurrence && ending > occurrence
            end
            return false
          else
            start <= effective_trigger && ending > effective_trigger
          end
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
            'ACTION'  => 1,
            'TRIGGER' => 1,

            'DURATION' => '?',
            'REPEAT'   => '?',

            'ATTACH' => '?'
          }
        end
      end
    end
  end
end
