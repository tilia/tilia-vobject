require 'test_helper'

module Tilia
  module VObject
    class VCardTest < Minitest::Test
      def assert_validate(vcf, options, expected_level, expected_message = nil)
        vcal = Tilia::VObject::Reader.read(vcf)
        result = vcal.validate(options)

        expect_validate_result(result, expected_level, expected_message)
      end

      def expect_validate_result(input, expected_level, expected_message = nil)
        messages = []
        input.each do |warning|
          messages << warning['message']
        end

        if expected_level == 0
          assert_equal(0, input.size, "No validation messages were expected. We got: #{messages.join(', ')}")
        else
          assert_equal(1, input.size, "We expected exactly 1 validation message, We got: #{messages.join(', ')}")

          assert_equal(expected_message, input[0]['message'])
          assert_equal(expected_level, input[0]['level'])
        end
      end

      def validate_data
        tests = []

        # Correct
        tests << [
          "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n",
          [],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n"
        ]

        # No VERSION
        tests << [
          "BEGIN:VCARD\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n",
          [
            'VERSION MUST appear exactly once in a VCARD component'
          ],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n"
        ]

        # Unknown version
        tests << [
          "BEGIN:VCARD\r\nVERSION:2.2\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n",
          [
            'Only vcard version 4.0 (RFC6350), version 3.0 (RFC2426) or version 2.1 (icm-vcard-2.1) are supported.'
          ],
          "BEGIN:VCARD\r\nVERSION:2.1\r\nFN:John Doe\r\nUID:foo\r\nEND:VCARD\r\n"
        ]

        # No FN
        tests << [
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nEND:VCARD\r\n",
          [
            'The FN property must appear in the VCARD component exactly 1 time'
          ],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nEND:VCARD\r\n"
        ]
        # No FN, N fallback
        tests << [
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nN:Doe;John;;;;;\r\nEND:VCARD\r\n",
          [
            'The FN property must appear in the VCARD component exactly 1 time'
          ],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nN:Doe;John;;;;;\r\nFN:John Doe\r\nEND:VCARD\r\n"
        ]
        # No FN, N fallback, no first name
        tests << [
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nN:Doe;;;;;;\r\nEND:VCARD\r\n",
          [
            'The FN property must appear in the VCARD component exactly 1 time'
          ],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nN:Doe;;;;;;\r\nFN:Doe\r\nEND:VCARD\r\n"
        ]

        # No FN, ORG fallback
        tests << [
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nORG:Acme Co.\r\nEND:VCARD\r\n",
          [
            'The FN property must appear in the VCARD component exactly 1 time'
          ],
          "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:foo\r\nORG:Acme Co.\r\nFN:Acme Co.\r\nEND:VCARD\r\n"
        ]
        tests
      end

      def test_validate
        validate_data.each do |data|
          (input, expected_warnings, expected_repaired_output) = data
          vcard = Tilia::VObject::Reader.read(input)

          warnings = vcard.validate

          warn_msg = []
          warnings.each do |warning|
            warn_msg << warning['message']
          end

          assert_equal(expected_warnings, warn_msg)

          vcard.validate(Tilia::VObject::Component::REPAIR)

          assert_equal(expected_repaired_output, vcard.serialize)
        end
      end

      def test_get_document_type
        vcard = Tilia::VObject::Component::VCard.new({}, false)
        vcard['VERSION'] = '2.1'
        assert_equal(Tilia::VObject::Component::VCard::VCARD21, vcard.document_type)

        vcard = Tilia::VObject::Component::VCard.new({}, false)
        vcard['VERSION'] = '3.0'
        assert_equal(Tilia::VObject::Component::VCard::VCARD30, vcard.document_type)

        vcard = Tilia::VObject::Component::VCard.new({}, false)
        vcard['VERSION'] = '4.0'
        assert_equal(Tilia::VObject::Component::VCard::VCARD40, vcard.document_type)

        vcard = Tilia::VObject::Component::VCard.new({}, false)
        assert_equal(Tilia::VObject::Component::VCard::UNKNOWN, vcard.document_type)
      end

      def test_preferred_no_pref
        vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
EMAIL:1@example.org
EMAIL:2@example.org
END:VCARD
VCF

        vcard = Tilia::VObject::Reader.read(vcard)
        assert_equal('1@example.org', vcard.preferred('EMAIL').value)
      end

      def test_preferred_with_pref
        vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
EMAIL:1@example.org
EMAIL;TYPE=PREF:2@example.org
END:VCARD
VCF

        vcard = Tilia::VObject::Reader.read(vcard)
        assert_equal('2@example.org', vcard.preferred('EMAIL').value)
      end

      def test_preferred_with40_pref
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
EMAIL:1@example.org
EMAIL;PREF=3:2@example.org
EMAIL;PREF=2:3@example.org
END:VCARD
VCF

        vcard = Tilia::VObject::Reader.read(vcard)
        assert_equal('3@example.org', vcard.preferred('EMAIL').value)
      end

      def test_preferred_not_found
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
END:VCARD
VCF

        vcard = Tilia::VObject::Reader.read(vcard)
        assert_nil(vcard.preferred('EMAIL'))
      end

      def test_no_uid_card_dav
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
FN:John Doe
END:VCARD
VCF
        assert_validate(
          vcard,
          Tilia::VObject::Component::VCard::PROFILE_CARDDAV,
          3,
          'vCards on CardDAV servers MUST have a UID property.'
        )
      end

      def test_no_uid_no_card_dav
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
FN:John Doe
END:VCARD
VCF
        assert_validate(
          vcard,
          0,
          2,
          'Adding a UID to a vCard property is recommended.'
        )
      end

      def test_no_uid_no_card_dav_repair
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
FN:John Doe
END:VCARD
VCF
        assert_validate(
          vcard,
          Tilia::VObject::Component::VCard::REPAIR,
          1,
          'Adding a UID to a vCard property is recommended.'
        )
      end

      def test_v_card21_card_dav
        vcard = <<VCF
BEGIN:VCARD
VERSION:2.1
FN:John Doe
UID:foo
END:VCARD
VCF
        assert_validate(
          vcard,
          Tilia::VObject::Component::VCard::PROFILE_CARDDAV,
          3,
          'CardDAV servers are not allowed to accept vCard 2.1.'
        )
      end

      def test_v_card21_no_card_dav
        vcard = <<VCF
BEGIN:VCARD
VERSION:2.1
FN:John Doe
UID:foo
END:VCARD
VCF
        assert_validate(
          vcard,
          0,
          0
        )
      end
    end
  end
end
