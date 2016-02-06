module Tilia
  module VObject
    # This class generates birthday calendars.
    class BirthdayCalendarGenerator
      # Input objects.
      #
      # @var array
      # RUBY: attr_accessor :objects

      # Default year.
      # Used for dates without a year.
      DEFAULT_YEAR = 2000

      # Output format for the SUMMARY.
      #
      # @var string
      # RUBY: attr_accessor :format

      # Creates the generator.
      #
      # Check the setTimeRange and setObjects methods for details about the
      # arguments.
      #
      # @param mixed objects
      def initialize(objects = nil)
        @objects = []
        @format = '%1s\'s Birthday'

        self.objects = objects if objects
      end

      # Sets the input objects.
      #
      # You must either supply a vCard as a string or as a Component/VCard object.
      # It's also possible to supply an array of strings or objects.
      #
      # @param mixed objects
      #
      # @return void
      def objects=(objects)
        objects = [objects] unless objects.is_a?(Array)

        @objects = []
        objects.each do |object|
          if object.is_a?(String)
            v_obj = Reader.read(object)
            unless v_obj.is_a?(Component::VCard)
              fail ArgumentError, 'String could not be parsed as Component::VCard by setObjects'
            end

            @objects << v_obj
          elsif object.is_a?(Component::VCard)
            @objects << object
          else
            fail ArgumentError, 'You can only pass strings or Component::VCard arguments to setObjects'
          end
        end
      end

      # Sets the output format for the SUMMARY
      #
      # @param string format
      #
      # @return void
      attr_writer :format

      # Parses the input data and returns a VCALENDAR.
      #
      # @return Component/VCalendar
      def result
        calendar = Component::VCalendar.new

        @objects.each do |object|
          # Skip if there is no BDAY property.
          next if object.select('BDAY').empty?

          # We've seen clients (ez-vcard) putting "BDAY:" properties
          # without a value into vCards. If we come across those, we'll
          # skip them.
          next if object['BDAY'].value.blank?

          # We're always converting to vCard 4.0 so we can rely on the
          # VCardConverter handling the X-APPLE-OMIT-YEAR property for us.
          object = object.convert(Document::VCARD40)

          # Skip if the card has no FN property.
          next unless object.key?('FN')

          # Skip if the BDAY property is not of the right type.
          next unless object['BDAY'].is_a?(Property::VCard::DateAndOrTime)

          # Skip if we can't parse the BDAY value.
          begin
            date_parts = DateTimeParser.parse_v_card_date_time(object['BDAY'].value)
          rescue InvalidDataException
            next
          end

          # Set a year if it's not set.
          unknown_year = false

          unless date_parts['year']
            object['BDAY'] = "#{DEFAULT_YEAR}-#{date_parts['month']}-#{date_parts['date']}"
            unknown_year = true
          end

          # Create event.
          event = calendar.add(
            'VEVENT',
            'SUMMARY'      => format(@format, object['FN'].value),
            'DTSTART'      => Time.zone.parse(object['BDAY'].value),
            'RRULE'        => 'FREQ=YEARLY',
            'TRANSP'       => 'TRANSPARENT'
          )

          # add VALUE=date
          event['DTSTART']['VALUE'] = 'DATE'

          # Add X-SABRE-BDAY property.
          if unknown_year
            event.add(
              'X-SABRE-BDAY',
              'BDAY',
              'X-SABRE-VCARD-UID' => object['UID'].value,
              'X-SABRE-VCARD-FN'  => object['FN'].value,
              'X-SABRE-OMIT-YEAR' => DEFAULT_YEAR
            )
          else
            event.add(
              'X-SABRE-BDAY',
              'BDAY',
              'X-SABRE-VCARD-UID' => object['UID'].value,
              'X-SABRE-VCARD-FN'  => object['FN'].value
            )
          end
        end

        calendar
      end
    end
  end
end
