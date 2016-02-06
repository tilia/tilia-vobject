require 'v_object/test_case'

module Tilia
  module VObject
    module ITip
      # Utilities for testing the broker
      class BrokerTester < TestCase
        def parse(old_message, new_message, expected = [], current_user = 'mailto:one@example.org')
          broker = Tilia::VObject::ITip::Broker.new
          result = broker.parse_event(new_message, current_user, old_message)

          assert_equal(expected.size, result.size)

          expected.each_with_index do |ex, index|
            message = result[index]

            ex.each do |key, val|
              if key == 'message'
                assert_v_obj_equals(val, message.message.serialize)
              else
                actual = message.send(key.underscore)
                assert_equal(val, val.is_a?(String) ? actual.to_s : actual)
              end
            end
          end
        end

        def process(input, existing_object = nil, expected = false)
          version = Tilia::VObject::Version::VERSION

          vcal = Tilia::VObject::Reader.read(input)

          main_component = vcal.components.first

          message = Tilia::VObject::ITip::Message.new
          message.message = vcal
          message.method = vcal.key?('METHOD') ? vcal['METHOD'].value : nil
          message.component = main_component.name
          message.uid = main_component['UID'].value
          message.sequence = vcal['VEVENT'] ? vcal['VEVENT'][0]['SEQUENCE'] : nil

          if message.method == 'REPLY'
            message.sender = main_component['ATTENDEE'].value
            message.sender_name = main_component['ATTENDEE'].key?('CN') ? main_component['ATTENDEE']['CN'].value : nil
            message.recipient = main_component['ORGANIZER'].value
            message.recipient_name = main_component['ORGANIZER'].key?('CN') ? main_component['ORGANIZER']['CN'] : nil
          end

          broker = Tilia::VObject::ITip::Broker.new

          if existing_object.is_a?(String)
            existing_object = existing_object.gsub(
              '%foo%',
              "VERSION:2.0\nPRODID:-//Tilia//Tilia VObject #{version}//EN\nCALSCALE:GREGORIAN"
            )
            existing_object = Tilia::VObject::Reader.read(existing_object)
          end

          result = broker.process_message(message, existing_object)

          if expected.nil?
            assert(!result)
            return nil
          end

          assert_v_obj_equals(expected, result)
        end
      end
    end
  end
end
