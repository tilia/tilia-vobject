module Tilia
  module VObject
    class Property
      # Boolean property.
      #
      # This object represents BOOLEAN values. These are always the case-insenstive
      # string TRUE or FALSE.
      #
      # Automatic conversion to PHP's true and false are done.
      class Boolean < Property
        # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
        #
        # This has been 'unfolded', so only 1 line will be passed. Unescaping is
        # not yet done, but parameters are not included.
        #
        # @param [String] val
        #
        # @return [void]
        def raw_mime_dir_value=(val)
          val = val.upcase == 'TRUE' ? true : false
          self.value = val
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return [String]
        def raw_mime_dir_value
          @value ? 'TRUE' : 'FALSE'
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return [String]
        def value_type
          'BOOLEAN'
        end

        # Hydrate data from a XML subtree, as it would appear in a xCard or xCal
        # object.
        #
        # @param [array] value
        #
        # @return [void]
        def xml_value=(value)
          value = value.map do |v|
            'true' == v
          end

          super(value)
        end
      end
    end
  end
end
