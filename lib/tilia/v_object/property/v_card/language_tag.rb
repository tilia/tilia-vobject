module Tilia
  module VObject
    class Property
      module VCard
        # LanguageTag property.
        #
        # This object represents LANGUAGE-TAG values as used in vCards.
        class LanguageTag < Property
          # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
          #
          # This has been 'unfolded', so only 1 line will be passed. Unescaping is
          # not yet done, but parameters are not included.
          #
          # @param [String] val
          #
          # @return [void]
          def raw_mime_dir_value=(val)
            self.value = val
          end

          # Returns a raw mime-dir representation of the value.
          #
          # @return [String]
          def raw_mime_dir_value
            value
          end

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return [String]
          def value_type
            'LANGUAGE-TAG'
          end
        end
      end
    end
  end
end
