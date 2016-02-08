module Tilia
  module VObject
    class Property
      module VCard
        # Date property.
        #
        # This object encodes vCard DATE values.
        class Date < DateAndOrTime
          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return [String]
          def value_type
            'DATE'
          end

          # Sets the property as a DateTime object.
          #
          # @param [\DateTimeInterface] dt
          #
          # @return [void]
          def date_time=(dt)
            @value = dt.strftime('%Y%m%d')
          end
        end
      end
    end
  end
end
