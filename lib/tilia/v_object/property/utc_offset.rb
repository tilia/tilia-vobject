module Tilia
  module VObject
    class Property
      # UtcOffset property.
      #
      # This object encodes UTC-OFFSET values.
      class UtcOffset < Text
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
          'UTC-OFFSET'
        end

        # Sets the JSON value, as it would appear in a jCard or jCal object.
        #
        # The value must always be an array.
        #
        # @param array value
        #
        # @return void
        def json_value=(value)
          value = value.map do |v|
            v.delete(':')
          end
          super(value)
        end

        # Returns the value, in the format it should be encoded for JSON.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          super.map do |value|
            "#{value[0...-2]}:#{value[-2..-1]}"
          end
        end

        def initialize(*args)
          super(*args)
          @delimiter = nil
        end
      end
    end
  end
end
