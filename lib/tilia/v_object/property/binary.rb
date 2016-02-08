require 'base64'
module Tilia
  module VObject
    class Property
      # BINARY property.
      #
      # This object represents BINARY values.
      #
      # Binary values are most commonly used by the iCalendar ATTACH property, and
      # the vCard PHOTO property.
      #
      # This property will transparently encode and decode to base64.
      class Binary < Property
        # In case this is a multi-value property. This string will be used as a
        # delimiter.
        #
        # @return [String, nil]
        attr_accessor :delimiter

        # Updates the current value.
        #
        # This may be either a single, or multiple strings in an array.
        #
        # @param [String|array] value
        #
        # @return [void]
        def value=(value)
          if value.is_a?(Array)
            if value.size == 1
              @value = value.first
            else
              fail ArgumentError, 'The argument must either be a string or an array with only one child'
            end
          else
            @value = value
          end
        end

        # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
        #
        # This has been 'unfolded', so only 1 line will be passed. Unescaping is
        # not yet done, but parameters are not included.
        #
        # @param [String] val
        #
        # @return [void]
        def raw_mime_dir_value=(val)
          @value = Base64.decode64(val)
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return [String]
        def raw_mime_dir_value
          Base64.strict_encode64(@value)
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return [String]
        def value_type
          'BINARY'
        end

        # Returns the value, in the format it should be encoded for json.
        #
        # This method must always return an array.
        #
        # @return [array]
        def json_value
          [Base64.strict_encode64(value)]
        end

        # Sets the json value, as it would appear in a jCard or jCal object.
        #
        # The value must always be an array.
        #
        # @param [array] value
        #
        # @return [void]
        def json_value=(value)
          value = value.map { |v| Base64.decode64(v) }
          super(value)
        end

        def initialize(*args)
          super(*args)
          @delimiter = nil
        end
      end
    end
  end
end
