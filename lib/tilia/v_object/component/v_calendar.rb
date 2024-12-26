module Tilia
  module VObject
    class Component
      # The VCalendar component.
      #
      # This component adds functionality to a component, specific for a VCALENDAR.
      class VCalendar < Document
        # The default name for this component.
        #
        # This should be 'VCALENDAR' or 'VCARD'.
        #
        # @return [String]
        @default_name = 'VCALENDAR'

        # This is a list of components, and which classes they should map to.
        #
        # @return [Hash]
        @component_map = {
          'VCALENDAR'     => Component::VCalendar,
          'VALARM'        => Component::VAlarm,
          'VEVENT'        => Component::VEvent,
          'VFREEBUSY'     => Component::VFreeBusy,
          'VAVAILABILITY' => Component::VAvailability,
          'AVAILABLE'     => Component::Available,
          'VJOURNAL'      => Component::VJournal,
          'VTIMEZONE'     => Component::VTimeZone,
          'VTODO'         => Component::VTodo
        }

        # List of value-types, and which classes they map to.
        #
        # @return [Hash]
        @value_map = {
          'BINARY'           => Property::Binary,
          'BOOLEAN'          => Property::Boolean,
          'CAL-ADDRESS'      => Property::ICalendar::CalAddress,
          'DATE'             => Property::ICalendar::Date,
          'DATE-TIME'        => Property::ICalendar::DateTime,
          'DURATION'         => Property::ICalendar::Duration,
          'FLOAT'            => Property::FloatValue,
          'INTEGER'          => Property::IntegerValue,
          'PERIOD'           => Property::ICalendar::Period,
          'RECUR'            => Property::ICalendar::Recur,
          'TEXT'             => Property::Text,
          'TIME'             => Property::Time,
          'UNKNOWN'          => Property::Unknown, # jCard / jCal-only.
          'URI'              => Property::Uri,
          'UTC-OFFSET'       => Property::UtcOffset
        }

        # List of properties, and which classes they map to.
        #
        # @return [Hash]
        @property_map = {
          # Calendar properties
          'CALSCALE'      => Property::FlatText,
          'METHOD'        => Property::FlatText,
          'PRODID'        => Property::FlatText,
          'VERSION'       => Property::FlatText,

          # Component properties
          'ATTACH'            => Property::Uri,
          'CATEGORIES'        => Property::Text,
          'CLASS'             => Property::FlatText,
          'COMMENT'           => Property::FlatText,
          'DESCRIPTION'       => Property::FlatText,
          'GEO'               => Property::FloatValue,
          'LOCATION'          => Property::FlatText,
          'PERCENT-COMPLETE'  => Property::IntegerValue,
          'PRIORITY'          => Property::IntegerValue,
          'RESOURCES'         => Property::Text,
          'STATUS'            => Property::FlatText,
          'SUMMARY'           => Property::FlatText,

          # Date and Time Component Properties
          'COMPLETED'     => Property::ICalendar::DateTime,
          'DTEND'         => Property::ICalendar::DateTime,
          'DUE'           => Property::ICalendar::DateTime,
          'DTSTART'       => Property::ICalendar::DateTime,
          'DURATION'      => Property::ICalendar::Duration,
          'FREEBUSY'      => Property::ICalendar::Period,
          'TRANSP'        => Property::FlatText,

          # Time Zone Component Properties
          'TZID'          => Property::FlatText,
          'TZNAME'        => Property::FlatText,
          'TZOFFSETFROM'  => Property::UtcOffset,
          'TZOFFSETTO'    => Property::UtcOffset,
          'TZURL'         => Property::Uri,

          # Relationship Component Properties
          'ATTENDEE'      => Property::ICalendar::CalAddress,
          'CONTACT'       => Property::FlatText,
          'ORGANIZER'     => Property::ICalendar::CalAddress,
          'RECURRENCE-ID' => Property::ICalendar::DateTime,
          'RELATED-TO'    => Property::FlatText,
          'URL'           => Property::Uri,
          'UID'           => Property::FlatText,

          # Recurrence Component Properties
          'EXDATE'        => Property::ICalendar::DateTime,
          'RDATE'         => Property::ICalendar::DateTime,
          'RRULE'         => Property::ICalendar::Recur,
          'EXRULE'        => Property::ICalendar::Recur, # Deprecated since rfc5545

          # Alarm Component Properties
          'ACTION'        => Property::FlatText,
          'REPEAT'        => Property::IntegerValue,
          'TRIGGER'       => Property::ICalendar::Duration,

          # Change Management Component Properties
          'CREATED'       => Property::ICalendar::DateTime,
          'DTSTAMP'       => Property::ICalendar::DateTime,
          'LAST-MODIFIED' => Property::ICalendar::DateTime,
          'SEQUENCE'      => Property::IntegerValue,

          # Request Status
          'REQUEST-STATUS' => Property::Text,

          # Additions from draft-daboo-valarm-extensions-04
          'ALARM-AGENT'    => Property::Text,
          'ACKNOWLEDGED'   => Property::ICalendar::DateTime,
          'PROXIMITY'      => Property::Text,
          'DEFAULT-ALARM'  => Property::Boolean,

          # Additions from draft-daboo-calendar-availability-05
          'BUSYTYPE'       => Property::Text
        }

        # Returns the current document type.
        #
        # @return [Integer]
        def document_type
          ICALENDAR20
        end

        # Returns a list of all 'base components'. For instance, if an Event has
        # a recurrence rule, and one instance is overridden, the overridden event
        # will have the same UID, but will be excluded from this list.
        #
        # VTIMEZONE components will always be excluded.
        #
        # @param [String] component_name filter by component name
        #
        # @return [Array<Component>]
        def base_components(component_name = nil)
          is_base_component = lambda do |component|
            return false unless component.is_a?(Component)
            return false if component.name == 'VTIMEZONE'
            return false if component.key?('RECURRENCE-ID')
            true
          end

          if component_name
            # Early exit
            return select(component_name).select is_base_component
          end

          components = []
          children.each do |child_group|
            do_skip = false
            child_group.each do |child|
              unless child.is_a?(Component)
                # If one child is not a component, they all are so we skip
                # the entire group.
                do_skip = true
                break
              end
              components << child if is_base_component.call(child)
            end
            next if do_skip
          end

          components
        end

        # Returns the first component that is not a VTIMEZONE, and does not have
        # an RECURRENCE-ID.
        #
        # If there is no such component, null will be returned.
        #
        # @param [String] component_name filter by component name
        #
        # @return [Component, nil]
        def base_component(component_name = nil)
          is_base_component = lambda do |component|
            return false unless component.is_a?(Component)
            return false if component.name == 'VTIMEZONE'
            return false if component.key?('RECURRENCE-ID')
            true
          end

          if component_name
            select(component_name).each do |child|
              return child if is_base_component.call(child)
            end
            return nil
          end

          children.each do |child_group|
            child_group.each do |child|
              return child if is_base_component.call(child)
            end
          end

          nil
        end

        # Expand all events in this VCalendar object and return a new VCalendar
        # with the expanded events.
        #
        # If this calendar object, has events with recurrence rules, this method
        # can be used to expand the event into multiple sub-events.
        #
        # Each event will be stripped from it's recurrence information, and only
        # the instances of the event in the specified timerange will be left
        # alone.
        #
        # In addition, this method will cause timezone information to be stripped,
        # and normalized to UTC.
        #
        # @param [Time] start
        # @param [Time] end
        # @param [ActiveSupport::TimeZone, nil] time_zone reference timezone for floating dates and
        #                                       times.
        #
        # @return [VCalendar]
        def expand(start, ending, time_zone = nil)
          new_children = []
          recurring_events = {}

          time_zone = ActiveSupport::TimeZone.new('UTC') unless time_zone

          strip_timezones = lambda do |component|
            component.children.each do |component_child|
              if component_child.is_a?(Property::ICalendar::DateTime) && component_child.time?
                dt = component_child.date_times(time_zone)

                # We only need to update the first timezone, because
                # setDateTimes will match all other timezones to the
                # first.
                dt[0] = dt[0].in_time_zone(ActiveSupport::TimeZone.new('UTC'))
                component_child.date_times = dt
              elsif component_child.is_a?(Component)
                strip_timezones.call(component_child)
              end
            end

            component
          end

          children.each do |child|
            if child.is_a?(Property) && child.name != 'PRODID'
              # We explictly want to ignore PRODID, because we want to
              # overwrite it with our own.
              new_children << child.clone
            elsif child.is_a?(Component) && child.name != 'VTIMEZONE'
              # We're also stripping all VTIMEZONE objects because we're
              # converting everything to UTC.

              if child.name == 'VEVENT' && (child.key?('RECURRENCE-ID') || child.key?('RRULE') || child.key?('RDATE'))
                # Handle these a bit later.
                uid = child['UID'].to_s

                fail InvalidDataException, 'Every VEVENT object must have a UID property' if uid.blank?

                if recurring_events.key?(uid)
                  recurring_events[uid] << child.clone
                else
                  recurring_events[uid] = [child.clone]
                end
              elsif child.name == 'VEVENT' && child.in_time_range?(start, ending)
                new_children << strip_timezones.call(child.clone)
              end
            end
          end

          recurring_events.each do |_uid, events|
            begin
              it = Recur::EventIterator.new(events, time_zone)
            rescue Recur::NoInstancesException
              # This event is recurring, but it doesn't have a single
              # instance. We are skipping this event from the output
              # entirely.
              next
            end

            it.fast_forward(start)

            while it.valid && it.dt_start < ending
              new_children << strip_timezones.call(it.event_object) if it.dt_end > start
              it.next
            end
          end

          self.class.new(new_children)
        end

        protected

        # This method should return a list of default property values.
        #
        # @return [Hash]
        def defaults
          {
            'VERSION'  => '2.0',
            'PRODID'   => "-//Tilia//Tilia VObject #{Version::VERSION}//EN",
            'CALSCALE' => 'GREGORIAN'
          }
        end

        public

        # (see Component#validation_rules)
        def validation_rules
          {
            'PRODID'  => 1,
            'VERSION' => 1,

            'CALSCALE' => '?',
            'METHOD'   => '?'
          }
        end

        # (see Component#validate)
        def validate(options = 0)
          warnings = super(options)

          ver = self['VERSION']
          if ver
            unless ver.to_s == '2.0'
              warnings << {
                'level'   => 3,
                'message' => 'Only iCalendar version 2.0 as defined in rfc5545 is supported.',
                'node'    => self
              }
            end
          end

          uid_list = {}
          components_found = 0
          component_types = []

          children.each do |child|
            next unless child.is_a?(Component)
            components_found += 1

            next unless ['VEVENT', 'VTODO', 'VJOURNAL'].include?(child.name)

            component_types << child.name

            uid = child['UID'].to_s
            is_master = child.key?('RECURRENCE-ID') ? 0 : 1

            if uid_list.key?(uid)
              uid_list[uid]['count'] += 1
              if is_master == 1 && uid_list[uid]['hasMaster'] > 0
                warnings << {
                  'level'   => 3,
                  'message' => "More than one master object was found for the object with UID #{uid}",
                  'node'    => self
                }
              end
              uid_list[uid]['hasMaster'] += is_master
            else
              uid_list[uid] = {
                'count'     => 1,
                'hasMaster' => is_master
              }
            end
          end

          if components_found == 0
            warnings << {
              'level'   => 3,
              'message' => 'An iCalendar object must have at least 1 component.',
              'node'    => self
            }
          end

          if options & PROFILE_CALDAV > 0
            if uid_list.size > 1
              warnings << {
                'level'   => 3,
                'message' => 'A calendar object on a CalDAV server may only have components with the same UID.',
                'node'    => self
              }
            end

            if component_types.size == 0
              warnings << {
                'level'   => 3,
                'message' => 'A calendar object on a CalDAV server must have at least 1 component (VTODO, VEVENT, VJOURNAL).',
                'node'    => self
              }
            end

            if component_types.uniq.size > 1
              warnings << {
                'level'   => 3,
                'message' => 'A calendar object on a CalDAV server may only have 1 type of component (VEVENT, VTODO or VJOURNAL).',
                'node'    => self
              }
            end

            if key?('METHOD')
              warnings <<
                {
                  'level'   => 3,
                  'message' => 'A calendar object on a CalDAV server MUST NOT have a METHOD property.',
                  'node'    => self
                }
            end
          end

          warnings
        end

        # Returns all components with a specific UID value.
        #
        # @return [array]
        def by_uid(uid)
          components.select do |item|
            item_uid = item.select('UID')
            if item_uid.empty?
              false
            else
              item_uid = item_uid.first.value
              uid == item_uid
            end
          end
        end
      end
    end
  end
end
