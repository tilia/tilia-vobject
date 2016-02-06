require 'test_helper'
require 'v_object/test_case'

module Tilia
  module VObject
    class BirthdayCalendarGeneratorTest < TestCase
      def test_vcard_string_with_valid_birthday
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_array_of_vcard_strings_with_valid_birthdays
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = []

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Doe;John;;Mr.
FN:John Doe
BDAY:19820210
UID:bar
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:John Doe's Birthday
DTSTART;VALUE=DATE:19820210
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=bar;X-SABRE-VCARD-FN=John Doe:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_array_of_vcard_strings_with_valid_birthdays_via_constructor
        input = []

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Doe;John;;Mr.
FN:John Doe
BDAY:19820210
UID:bar
END:VCARD
VCF

        generator = Tilia::VObject::BirthdayCalendarGenerator.new(input)

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:John Doe's Birthday
DTSTART;VALUE=DATE:19820210
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=bar;X-SABRE-VCARD-FN=John Doe:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_object_with_valid_birthday
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        input = Tilia::VObject::Reader.read(input)

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_array_of_vcard_objects_with_valid_birthdays
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = []

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Doe;John;;Mr.
FN:John Doe
BDAY:19820210
UID:bar
END:VCARD
VCF

        input.map! { |v| Tilia::VObject::Reader.read(v) }

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:John Doe's Birthday
DTSTART;VALUE=DATE:19820210
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=bar;X-SABRE-VCARD-FN=John Doe:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_valid_birthday_with_x_apple_omit_year
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY;X-APPLE-OMIT-YEAR=1604:1604-04-07
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:20000407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump;X-SABRE-OMIT-YEAR=2000:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_valid_birthday_without_year
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:4.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:--04-07
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Birthday
DTSTART;VALUE=DATE:20000407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump;X-SABRE-OMIT-YEAR=2000:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_invalid_birthday
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:foo
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_no_birthday
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_valid_birthday_localized
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:**ANY**
DTSTAMP:**ANY**
SUMMARY:Forrest Gump's Geburtstag
DTSTART;VALUE=DATE:19850407
RRULE:FREQ=YEARLY
TRANSP:TRANSPARENT
X-SABRE-BDAY;X-SABRE-VCARD-UID=foo;X-SABRE-VCARD-FN=Forrest Gump:BDAY
END:VEVENT
END:VCALENDAR
ICS

        generator.objects = input
        generator.format = '%1s\'s Geburtstag'
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_vcard_string_with_empty_birthday_property
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end

      def test_parse_exception
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<INVALID
BEGIN:FOO
FOO:Bar
END:FOO
INVALID

        assert_raises(Tilia::VObject::ParseException) { generator.objects = input }
      end

      def test_invalid_argument_exception
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:Foo
DTSTART;VALUE=DATE:19850407
END:VEVENT
END:VCALENDAR
ICS

        assert_raises(ArgumentError) { generator.objects = input }
      end

      def test_invalid_argument_exception_for_partially_invalid_array
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = []

        input << <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
FN:Forrest Gump
BDAY:19850407
UID:foo
END:VCARD
VCF
        calendar = Tilia::VObject::Component::VCalendar.new

        input = calendar.add(
          'VEVENT',
          'SUMMARY'      => 'Foo',
          'DTSTART'      => Time.zone.parse('NOW')
        )

        assert_raises(ArgumentError) { generator.objects = input }
      end

      def test_broken_vcard_without_fn
        generator = Tilia::VObject::BirthdayCalendarGenerator.new
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.
BDAY:19850407
UID:foo
END:VCARD
VCF

        expected = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
ICS

        generator.objects = input
        output = generator.result

        assert_v_obj_equals(expected, output)
      end
    end
  end
end
