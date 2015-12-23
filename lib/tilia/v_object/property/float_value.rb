module Tilia
  module VObject
    class Property
      # Float property.
      #
      # This object represents FLOAT values. These can be 1 or more floating-point
      # numbers.
      class FloatValue < Property
        # In case this is a multi-value property. This string will be used as a
        # delimiter.
        #
        # @var string|null
        attr_accessor :delimiter

        # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
        #
        # This has been 'unfolded', so only 1 line will be passed. Unescaping is
        # not yet done, but parameters are not included.
        #
        # @param string val
        #
        # @return void
        def raw_mime_dir_value=(val)
          val = val.split(@delimiter)
          val = val.map(&:to_f)
          self.parts = val
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return string
        def raw_mime_dir_value
          parts.join(@delimiter)
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'FLOAT'
        end

        # Returns the value, in the format it should be encoded for JSON.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          val = parts.map(&:to_f)

          # Special-casing the GEO property.
          #
          # See:
          # http://tools.ietf.org/html/draft-ietf-jcardcal-jcal-04#section-3.4.1.2
          return [val] if @name == 'GEO'

          val
        end

        # Hydrate data from a XML subtree, as it would appear in a xCard or xCal
        # object.
        #
        # @param array value
        #
        # @return void
        def xml_value=(value)
          value = value.values if value.is_a?(Hash)
          value = value.map(&:to_f)
          super(value)
        end

        protected

        # This method serializes only the value of a property. This is used to
        # create xCard or xCal documents.
        #
        # @param Xml\Writer writer  XML writer.
        #
        # @return void
        def xml_serialize_value(writer)
          # Special-casing the GEO property.
          #
          # See:
          # http://tools.ietf.org/html/rfc6321#section-3.4.1.2
          if @name == 'GEO'
            value = parts.map(&:to_f)

            writer.write_element('latitude', value[0])
            writer.write_element('longitude', value[1])
          else
            super(writer)
          end
        end

        public

        def initialize(*args)
          super(*args)
          @delimiter = ';'
        end
      end
    end
  end
end
