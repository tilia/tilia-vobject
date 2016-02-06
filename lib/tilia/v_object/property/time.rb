module Tilia
  module VObject
    class Property
      # Time property.
      #
      # This object encodes TIME values.
      class Time < Text
        # In case this is a multi-value property. This string will be used as a
        # delimiter.
        #
        # @var string|null
        attr_accessor :delimiter

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'TIME'
        end

        # Sets the JSON value, as it would appear in a jCard or jCal object.
        #
        # The value must always be an array.
        #
        # @param array value
        # @return void
        def json_value=(value)
          # Removing colons from value.
          value = value.map{ |v| v.gsub(':', '') }

          if value.size == 1
            self.value = value.first
          else
            self.value = value
          end
        end

        # Returns the value, in the format it should be encoded for json.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          parts = DateTimeParser.parse_v_card_time(value)
          time_str = ''

          # Hour
          if !parts['hour'].nil?
            time_str += parts['hour']

            time_str += ':' unless parts['minute'].nil?
          else
            # We know either minute or second _must_ be set, so we insert a
            # dash for an empty value.
            time_str += '-'
          end

          # Minute
          if !parts['minute'].nil?
            time_str += parts['minute']

            time_str += ':' unless parts['second'].nil?
          else
            if parts['second']
              # Dash for empty minute
              time_str += '-'
            end
          end

          # Second
          time_str += parts['second'] unless parts['second'].nil?

          # Timezone
          unless parts['timezone'].nil?
            if parts['timezone'] == 'Z'
              time_str += 'Z'
            else
              time_str += parts['timezone'].gsub(/([0-9]{2})([0-9]{2})$/) { "#{$1}:#{$2}" }
            end
          end

          [time_str]
        end

        # Hydrate data from a XML subtree, as it would appear in a xCard or xCal
        # object.
        #
        # @param array value
        #
        # @return void
        def xml_value=(value)
          value = value.map do |v|
            v.delete(':')
          end
          super(value)
        end

        def initialize(*args)
          super(*args)
          @delimiter = nil
        end
      end
    end
  end
end
