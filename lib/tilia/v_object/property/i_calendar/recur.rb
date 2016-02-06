module Tilia
  module VObject
    class Property
      module ICalendar
        # Recur property.
        #
        # This object represents RECUR properties.
        # These values are just used for RRULE and the now deprecated EXRULE.
        #
        # The RRULE property may look something like this:
        #
        # RRULE:FREQ=MONTHLY;BYDAY=1,2,3;BYHOUR=5.
        #
        # This property exposes this as a key=>value array that is accessible using
        # getParts, and may be set using setParts.
        class Recur < Property
          # Updates the current value.
          #
          # This may be either a single, or multiple strings in an array.
          #
          # @param string|array value
          #
          # @return void
          def value=(value)
            # If we're getting the data from json, we'll be receiving an object
            value = [value] if false # value.is_a?(Array) TODO

            if value.is_a?(Hash)
              new_val = {}
              value.each do |k, v|
                if v.is_a?(String)
                  v = v.upcase

                  # The value had multiple sub-values
                  v = v.split(',') if v.index(',')
                  v = v.gsub(/[:\-]/, '') if k == 'until'
                else
                  v = v.map { |val| val.is_a?(String) ? val.upcase : val }
                end

                new_val[k.upcase] = v
              end

              @value = new_val
            elsif value.is_a?(String)
              @value = self.class.string_to_array(value)
            else
              fail ArgumentError, 'You must either pass a string, or a key=>value array'
            end
          end

          # Returns the current value.
          #
          # This method will always return a singular value. If this was a
          # multi-value object, some decision will be made first on how to represent
          # it as a string.
          #
          # To get the correct multi-value version, use getParts.
          #
          # @return string
          def value
            out = []
            @value.each do |key, value|
              out << "#{key}=#{value.is_a?(Array) ? value.join(',') : value}"
            end
            out.join(';').upcase
          end

          # Sets a multi-valued property.
          #
          # @param array parts
          # @return void
          def parts=(parts)
            self.value = parts
          end

          # Returns a multi-valued property.
          #
          # This method always returns an array, if there was only a single value,
          # it will still be wrapped in an array.
          #
          # @return array
          def parts
            @value
          end

          # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
          #
          # This has been 'unfolded', so only 1 line will be passed. Unescaping is
          # not yet done, but parameters are not included.
          #
          # @param string val
          # @return void
          def raw_mime_dir_value=(val)
            self.value = val
          end

          # Returns a raw mime-dir representation of the value.
          #
          # @return string
          def raw_mime_dir_value
            value
          end

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return string
          def value_type
            'RECUR'
          end

          # Returns the value, in the format it should be encoded for json.
          #
          # This method must always return an array.
          #
          # @return array
          def json_value
            values = {}
            parts.each do |k, v|
              values[k.downcase] = v
            end
            [values]
          end

          protected

          # This method serializes only the value of a property. This is used to
          # create xCard or xCal documents.
          #
          # @param Xml\Writer writer  XML writer.
          # @return void
          def xml_serialize_value(writer)
            value_type = self.value_type.downcase

            json_value.each do |value|
              writer.write_element(value_type, value)
            end
          end

          public

          # Parses an RRULE value string, and turns it into a struct-ish array.
          #
          # @param string value
          # @return array
          def self.string_to_array(value)
            value = value.upcase
            new_value = {}
            value.split(';').each do |part|
              # Skipping empty parts.
              next if part.blank?

              (part_name, part_value) = part.split('=')

              # The value itself had multiple values..
              part_value = part_value.split(',') if part_value.index(',')

              new_value[part_name] = part_value
            end

            new_value
          end
        end
      end
    end
  end
end
