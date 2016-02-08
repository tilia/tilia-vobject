module Tilia
  module VObject
    class Property
      module ICalendar
        # Duration property.
        #
        # This object represents DURATION values, as defined here:
        #
        # http://tools.ietf.org/html/rfc5545#section-3.3.6
        class Duration < Property
          # In case this is a multi-value property. This string will be used as a
          # delimiter.
          #
          # @return [String, nil]
          attr_accessor :delimiter

          # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
          #
          # This has been 'unfolded', so only 1 line will be passed. Unescaping is
          # not yet done, but parameters are not included.
          #
          # @param [String] val
          #
          # @return [void]
          def raw_mime_dir_value=(val)
            self.value = val.split(@delimiter)
          end

          # Returns a raw mime-dir representation of the value.
          #
          # @return [String]
          def raw_mime_dir_value
            parts.join(@delimiter)
          end

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return [String]
          def value_type
            'DURATION'
          end

          # Returns a DateInterval representation of the Duration property.
          #
          # If the property has more than one value, only the first is returned.
          #
          # @return [\DateInterval]
          def date_interval
            parts = self.parts
            value = parts[0]
            DateTimeParser.parse_duration(value)
          end

          def initialize(*args)
            super(*args)
            @delimiter = ','
          end
        end
      end
    end
  end
end
