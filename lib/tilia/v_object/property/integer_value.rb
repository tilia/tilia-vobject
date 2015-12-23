module Tilia
  module VObject
    class Property
      # Integer property.
      #
      # This object represents INTEGER values. These are always a single integer.
      # They may be preceeded by either + or -.
      class IntegerValue < Property
        # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
        #
        # This has been 'unfolded', so only 1 line will be passed. Unescaping is
        # not yet done, but parameters are not included.
        #
        # @param string val
        #
        # @return void
        def raw_mime_dir_value=(val)
          self.value = val.to_i
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return string
        def raw_mime_dir_value
          @value
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'INTEGER'
        end

        # Returns the value, in the format it should be encoded for json.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          [value.to_i]
        end

        # Hydrate data from a XML subtree, as it would appear in a xCard or xCal
        # object.
        #
        # @param array value
        #
        # @return void
        def xml_value=(value)
          value = value.map &:to_i
          super(value)
        end
      end
    end
  end
end
