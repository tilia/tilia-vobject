require 'digest'
module Tilia
  module VObject
    module Splitter
      # Splitter.
      #
      # This class is responsible for splitting up iCalendar objects.
      #
      # This class expects a single VCALENDAR object with one or more
      # calendar-objects inside. Objects with identical UID's will be combined into
      # a single object.
      class ICalendar
        include SplitterInterface

        # Timezones.
        #
        # @return [array]
        # RUBY: attr_accessor :vtimezones

        # iCalendar objects.
        #
        # @return [array]
        # RUBY: attr_accessor :objects

        # Constructor.
        #
        # The splitter should receive an readable file stream as it's input.
        #
        # @param [resource] input
        # @param [Integer] options Parser options, see the OPTIONS constants.
        def initialize(input, options = 0)
          @vtimezones = {}
          @objects = {}

          data = Reader.read(input, options)

          unless data.is_a?(Component::VCalendar)
            fail ParseException, 'Supplied input could not be parsed as VCALENDAR.'
          end

          data.children.each do |component|
            next unless component.is_a? Component

            if component.name == 'VTIMEZONE'
              @vtimezones[component['TZID'].to_s] = component
              next
            end

            # Get component UID for recurring Events search
            if component['UID'].blank?
              component['UID'] = "#{Digest::SHA1.hexdigest(Time.now.to_s + rand.to_s)}-vobjectimport"
            end

            uid = component['UID'].to_s

            # Take care of recurring events
            @objects[uid] = Component::VCalendar.new unless @objects.key?(uid)

            @objects[uid].add(component.dup)
          end
        end

        # Every time self.next is called, a new object will be parsed, until we
        # hit the end of the stream.
        #
        # When the end is reached, null will be returned.
        #
        # @return [Sabre\VObject\Component, nil]
        def next
          key = @objects.keys.first

          if key
            object = @objects.delete(key)

            # create our baseobject
            object['VERSION'] = '2.0'
            object['PRODID'] = "-//Tilia//Tilia VObject #{Version::VERSION}//EN"
            object['CALSCALE'] = 'GREGORIAN'

            # add vtimezone information to obj (if we have it)
            @vtimezones.keys.each do |vtimezone|
              object.add(@vtimezones[vtimezone])
            end

            return object
          else
            return nil
          end

          nil
        end
      end
    end
  end
end
