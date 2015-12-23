module Tilia
  module VObject
    class Property
      module VCard
        # TimeStamp property.
        #
        # This object encodes TIMESTAMP values.
        class TimeStamp < Text
          # In case this is a multi-value property. This string will be used as a
          # delimiter.
          #
          # @var string|null
          attr_accessor :delimiter

          # Returns the type of value.
          #
          # This corresponds to the VALUE= parameter. Every property also has a
          # 'default' valueType.
          #
          # @return string
          def value_type
            'TIMESTAMP'
          end

          # Returns the value, in the format it should be encoded for json.
          #
          # This method must always return an array.
          #
          # @return array
          def json_value
            parts = DateTimeParser.parse_v_card_date_time(value)

            date_str = format(
              '%04i-%02i-%02iT%02i:%02i:%02i',
              parts['year'],
              parts['month'],
              parts['date'],
              parts['hour'],
              parts['minute'],
              parts['second']
            )

            # Timezone
            date_str += parts['timezone'] unless parts['timezone'].blank?

            [date_str]
          end

          protected

          # This method serializes only the value of a property. This is used to
          # create xCard or xCal documents.
          #
          # @param Xml\Writer writer  XML writer.
          #
          # @return void
          def xml_serialize_value(writer)
            # xCard is the only XML and JSON format that has the same date and time
            # format than vCard.
            value_type = self.value_type.downcase
            writer.write_element(value_type, value)
          end

          public

          def initialize(*args)
            super(*args)
            @delimiter = nil
          end
        end
      end
    end
  end
end
