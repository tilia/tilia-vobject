module Tilia
  module VObject
    class Property
      # Unknown property.
      #
      # This object represents any properties not recognized by the parser.
      # This type of value has been introduced by the jCal, jCard specs.
      class Unknown < Text
        # Returns the value, in the format it should be encoded for json.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          [raw_mime_dir_value]
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'UNKNOWN'
        end
      end
    end
  end
end
