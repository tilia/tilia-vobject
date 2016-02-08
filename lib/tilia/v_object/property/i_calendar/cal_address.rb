module Tilia
  module VObject
    class Property
      module ICalendar
        # CalAddress property.
        #
        # This object encodes CAL-ADDRESS values, as defined in rfc5545
        class CalAddress < Text
          # In case this is a multi-value property. This string will be used as a
          # delimiter.
          #
          # @return [String, nil]
          attr_accessor :delimiter

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return [String]
          def value_type
            'CAL-ADDRESS'
          end

          # This returns a normalized form of the value.
          #
          # This is primarily used right now to turn mixed-cased schemes in user
          # uris to lower-case.
          #
          # Evolution in particular tends to encode mailto: as MAILTO:.
          #
          # @return [String]
          def normalized_value
            input = value
            return input unless input.index(':')

            (schema, everything_else) = input.split(':', 2)
            "#{schema.downcase}:#{everything_else}"
          end

          def initialize(*args)
            super(*args)
            @delimiter = nil
          end
        end
      end
    end
  end
end
