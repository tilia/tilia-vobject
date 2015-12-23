require 'test_helper'
require 'stringio'

module Tilia
  module VObject
    class VCardTest < Minitest::Test
      def create_stream(data)
        stream = StringIO.new
        stream.write(data)
        stream.rewind
        stream
      end

      def test_v_card_import_valid_v_card
        data = <<EOT
BEGIN:VCARD
UID:foo
END:VCARD
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::VCard.new(temp_file)

        count = 0
        count += 1 while objects.next
        assert_equal(1, count)
      end

      def test_v_card_import_wrong_type
        event = []
        event << <<EOT
BEGIN:VEVENT
UID:foo1
DTSTAMP:20140122T233226Z
DTSTART:20140101T050000Z
END:VEVENT
EOT

        event << <<EOT
BEGIN:VEVENT
UID:foo2
DTSTAMP:20140122T233226Z
DTSTART:20140101T060000Z
END:VEVENT
EOT

        data = <<EOT
BEGIN:VCALENDAR
#{event[0]}
#{event[1]}
END:VCALENDAR
EOT
        temp_file = create_stream(data)

        splitter = Tilia::VObject::Splitter::VCard.new(temp_file)

        assert_raises(Tilia::VObject::ParseException) do
          while object = splitter.next
          end
        end
      end

      def test_v_card_import_valid_v_cards_with_categories
        data = <<EOT
BEGIN:VCARD
UID:card-in-foo1-and-foo2
CATEGORIES:foo1,foo2
END:VCARD
BEGIN:VCARD
UID:card-in-foo1
CATEGORIES:foo1
END:VCARD
BEGIN:VCARD
UID:card-in-foo3
CATEGORIES:foo3
END:VCARD
BEGIN:VCARD
UID:card-in-foo1-and-foo3
CATEGORIES:foo1\,foo3
END:VCARD
EOT
        temp_file = create_stream(data)

        splitter = Tilia::VObject::Splitter::VCard.new(temp_file)

        count = 0
        count += 1 while splitter.next
        assert_equal(4, count)
      end

      def test_v_card_import_end_of_data
        data = <<EOT
BEGIN:VCARD
UID:foo
END:VCARD
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::VCard.new(temp_file)
        object = objects.next

        assert_nil(objects.next)
      end

      def test_v_card_import_check_invalid_argument_exception
        data = <<EOT
BEGIN:FOO
END:FOO
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::VCard.new(temp_file)
        assert_raises(Tilia::VObject::ParseException) do
          while object = objects.next
          end
        end
      end

      def test_v_card_import_multiple_valid_v_cards
        data = <<EOT
BEGIN:VCARD
UID:foo
END:VCARD
BEGIN:VCARD
UID:foo
END:VCARD
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::VCard.new(temp_file)

        count = 0
        count += 1 while objects.next
        assert_equal(2, count)
      end

      def test_import_multiple_separated_with_new_lines
        data = <<EOT
BEGIN:VCARD
UID:foo
END:VCARD


BEGIN:VCARD
UID:foo
END:VCARD


EOT
        temp_file = create_stream(data)
        objects = Tilia::VObject::Splitter::VCard.new(temp_file)

        count = 0
        count += 1 while objects.next
        assert_equal(2, count)
      end

      def test_v_card_import_v_card_without_uid
        data = <<EOT
BEGIN:VCARD
END:VCARD
EOT
        temp_file = create_stream(data)

        objects = Tilia::VObject::Splitter::VCard.new(temp_file)

        count = 0
        count += 1 while objects.next
        assert_equal(1, count)
      end
    end
  end
end
