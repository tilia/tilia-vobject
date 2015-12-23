require 'test_helper'

module Tilia
  module VObject
    class VAvailabilityTest < Minitest::Test
      def assert_is_valid(document)
        validation_result = document.validate
        if validation_result.any?
          messages = validation_result.map { |i| i['message'] }
          fail "Failed to assert that the supplied document is a valid document. Validation messages: #{messages.join(', ')}"
        end
        assert_equal(0, document.validate.size)
      end

      def assert_is_not_valid(document)
        assert(document.validate.size > 0)
      end

      def template(properties)
        vcal = <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
…
END:VAVAILABILITY
END:VCALENDAR
VCAL
        _template(vcal, properties)
      end

      def template_available(properties)
        vcal = <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
UID:foo@test
DTSTAMP:20111005T133225Z
DTSTART:20111005T133225Z
…
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL

        _template(vcal, properties)
      end

      def _template(template, properties)
        template.gsub('…', properties.join("\r\n"))
      end

      def test_v_availability_component
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
END:VAVAILABILITY
END:VCALENDAR
VCAL
        document = Tilia::VObject::Reader.read(vcal)

        assert_kind_of(Tilia::VObject::Component::VAvailability, document['VAVAILABILITY'])
      end

      def test_get_effective_start_end
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20150717T162200Z
DTEND:20150717T172200Z
END:VAVAILABILITY
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2015-07-17 16:22:00'),
            tz.parse('2015-07-17 17:22:00')
          ],
          document['VAVAILABILITY'].effective_start_end
        )
      end

      def test_get_effective_start_duration
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20150717T162200Z
DURATION:PT1H
END:VAVAILABILITY
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        tz = ActiveSupport::TimeZone.new('UTC')
        assert_equal(
          [
            tz.parse('2015-07-17 16:22:00'),
            tz.parse('2015-07-17 17:22:00')
          ],
          document['VAVAILABILITY'].effective_start_end
        )
      end

      def test_get_effective_start_end_unbound
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
END:VAVAILABILITY
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        assert_equal(
          [
            nil,
            nil
          ],
          document['VAVAILABILITY'].effective_start_end
        )
      end

      def test_is_in_time_range_unbound
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
END:VAVAILABILITY
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        assert(document['VAVAILABILITY'].in_time_range?(Time.zone.parse('2015-07-17'), Time.zone.parse('2015-07-18')))
      end

      def test_is_in_time_range_outside
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
DTSTART:20140101T000000Z
DTEND:20140102T000000Z
END:VAVAILABILITY
END:VCALENDAR
VCAL

        document = Tilia::VObject::Reader.read(vcal)
        refute(document['VAVAILABILITY'].in_time_range?(Time.zone.parse('2015-07-17'), Time.zone.parse('2015-07-18')))
      end

      def test_rf_cxxx_section3_1_availabilityprop_required
        # UID and DTSTAMP are present.
        assert_is_valid(Tilia::VObject::Reader.read(
                          <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # UID and DTSTAMP are missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # DTSTAMP is missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # UID is missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
DTSTAMP:20111005T133225Z
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))
      end

      def test_rf_cxxx_section3_1_availabilityprop_optional_once
        properties = [
          'BUSYTYPE:BUSY',
          'CLASS:PUBLIC',
          'CREATED:20111005T135125Z',
          'DESCRIPTION:Long bla bla',
          'DTSTART:20111005T020000',
          'LAST-MODIFIED:20111005T135325Z',
          'ORGANIZER:mailto:foo@example.com',
          'PRIORITY:1',
          'SEQUENCE:0',
          'SUMMARY:Bla bla',
          'URL:http://example.org/'
        ]

        # They are all present, only once.
        assert_is_valid(Tilia::VObject::Reader.read(template(properties)))

        # We duplicate each one to see if it fails.
        properties.each do |property|
          assert_is_not_valid(Tilia::VObject::Reader.read(template([property, property])))
        end
      end

      def test_rf_cxxx_section3_1_availabilityprop_dtend_duration
        # Only DTEND.
        assert_is_valid(Tilia::VObject::Reader.read(template(['DTEND:21111005T133225Z'])))

        # Only DURATION.
        assert_is_valid(Tilia::VObject::Reader.read(template(['DURATION:PT1H'])))

        # Both (not allowed).
        assert_is_not_valid(Tilia::VObject::Reader.read(template(['DTEND:21111005T133225Z', 'DURATION:PT1H'])))
      end

      def test_available_sub_component
        vcal = <<VCAL
BEGIN:VCALENDAR
BEGIN:VAVAILABILITY
BEGIN:AVAILABLE
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        document = Tilia::VObject::Reader.read(vcal)

        assert_kind_of(Tilia::VObject::Component, document['VAVAILABILITY']['AVAILABLE'])
      end

      def test_rf_cxxx_section3_1_availableprop_required
        # UID, DTSTAMP and DTSTART are present.
        assert_is_valid(Tilia::VObject::Reader.read(
                          <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
UID:foo@test
DTSTAMP:20111005T133225Z
DTSTART:20111005T133225Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # UID, DTSTAMP and DTSTART are missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # UID is missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
DTSTAMP:20111005T133225Z
DTSTART:20111005T133225Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # DTSTAMP is missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
UID:foo@test
DTSTART:20111005T133225Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))

        # DTSTART is missing.
        assert_is_not_valid(Tilia::VObject::Reader.read(
                              <<VCAL
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//id
BEGIN:VAVAILABILITY
UID:foo@test
DTSTAMP:20111005T133225Z
BEGIN:AVAILABLE
UID:foo@test
DTSTAMP:20111005T133225Z
END:AVAILABLE
END:VAVAILABILITY
END:VCALENDAR
VCAL
        ))
      end

      def test_rf_cxxx_section3_1_available_dtend_duration
        # Only DTEND.
        assert_is_valid(Tilia::VObject::Reader.read(template_available(['DTEND:21111005T133225Z'])))

        # Only DURATION.
        assert_is_valid(Tilia::VObject::Reader.read(template_available(['DURATION:PT1H'])))

        # Both (not allowed).
        assert_is_not_valid(Tilia::VObject::Reader.read(template_available(['DTEND:21111005T133225Z', 'DURATION:PT1H'])))
      end

      def test_rf_cxxx_section3_1_available_optional_once
        properties = [
          'CREATED:20111005T135125Z',
          'DESCRIPTION:Long bla bla',
          'LAST-MODIFIED:20111005T135325Z',
          'RECURRENCE-ID;RANGE=THISANDFUTURE:19980401T133000Z',
          'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
          'SUMMARY:Bla bla'
        ]

        # They are all present, only once.
        assert_is_valid(Tilia::VObject::Reader.read(template_available(properties)))

        # We duplicate each one to see if it fails.
        properties.each do |property|
          assert_is_not_valid(Tilia::VObject::Reader.read(template_available([property, property])))
        end
      end

      def test_rf_cxxx_section3_2
        assert_equal('BUSY', Tilia::VObject::Reader.read(template_available(['BUSYTYPE:BUSY']))['VAVAILABILITY']['AVAILABLE']['BUSYTYPE'].value)
        assert_equal('BUSY-UNAVAILABLE', Tilia::VObject::Reader.read(template_available(['BUSYTYPE:BUSY-UNAVAILABLE']))['VAVAILABILITY']['AVAILABLE']['BUSYTYPE'].value)
        assert_equal('BUSY-TENTATIVE', Tilia::VObject::Reader.read(template_available(['BUSYTYPE:BUSY-TENTATIVE']))['VAVAILABILITY']['AVAILABLE']['BUSYTYPE'].value)
      end
    end
  end
end
