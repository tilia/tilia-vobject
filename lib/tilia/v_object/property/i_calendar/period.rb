module Tilia
  module VObject
    class Property
      module ICalendar
        # Period property.
        #
        # This object represents PERIOD values, as defined here:
        #
        # http://tools.ietf.org/html/rfc5545#section-3.8.2.6
        class Period < Property
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
            self.value = val.split(@delimiter)
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
            'PERIOD'
          end

          # Sets the json value, as it would appear in a jCard or jCal object.
          #
          # The value must always be an array.
          #
          # @param array value
          #
          # @return void
          def json_value=(value)
            value = value.values if value.is_a?(Hash)
            value = value.map do |item|
              item = item.values if item.is_a?(Hash)
              item.join('/').delete(':').delete('-')
            end
            super(value)
          end

          # Returns the value, in the format it should be encoded for json.
          #
          # This method must always return an array.
          #
          # @return array
          def json_value
            result = []
            parts.each do |item|
              (start, ending) = item.split('/', 2)

              start = Tilia::VObject::DateTimeParser.parse_date_time(start)

              # This is a duration value.
              if ending[0] == 'P'
                result << [
                  start.strftime('%Y-%m-%dT%H:%M:%S'),
                  ending
                ]
              else
                ending = Tilia::VObject::DateTimeParser.parse_date_time(ending)
                result << [
                  start.strftime('%Y-%m-%dT%H:%M:%S'),
                  ending.strftime('%Y-%m-%dT%H:%M:%S')
                ]
              end
            end

            result
          end

          protected

          # This method serializes only the value of a property. This is used to
          # create xCard or xCal documents.
          #
          # @param Xml\Writer writer  XML writer.
          #
          # @return void
          def xml_serialize_value(writer)
            writer.start_element(value_type.downcase)

            value = json_value
            writer.write_element('start', value[0][0])

            if value[0][1][0] == 'P'
              writer.write_element('duration', value[0][1])
            else
              writer.write_element('end', value[0][1])
            end
            writer.end_element
          end

          public

          def initialize(*args)
            super(*args)
            @delimiter = ','
          end
        end
      end
    end
  end
end
