module Tilia
  module VObject
    class Property
      module VCard
        # DateTime property.
        #
        # This object encodes DATE-TIME values for vCards.
        class DateTime < DateAndOrTime
          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return [String]
          def value_type
            'DATE-TIME'
          end
        end
      end
    end
  end
end
