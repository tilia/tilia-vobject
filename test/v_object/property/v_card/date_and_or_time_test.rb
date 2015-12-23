require 'test_helper'

module Tilia
  module VObject
    class DateAndOrTimeTest < Minitest::Test
      def dates
        [
          [
            '19961022T140000',
            '1996-10-22T14:00:00'
          ],
          [
            '--1022T1400',
            '--10-22T14:00'
          ],
          [
            '---22T14',
            '---22T14'
          ],
          [
            '19850412',
            '1985-04-12'
          ],
          [
            '1985-04',
            '1985-04'
          ],
          [
            '1985',
            '1985'
          ],
          [
            '--0412',
            '--04-12'
          ],
          [
            'T102200',
            'T10:22:00'
          ],
          [
            'T1022',
            'T10:22'
          ],
          [
            'T10',
            'T10'
          ],
          [
            'T-2200',
            'T-22:00'
          ],
          [
            'T102200Z',
            'T10:22:00Z'
          ],
          [
            'T102200-0800',
            'T10:22:00-0800'
          ],
          [
            'T--00',
            'T--00'
          ]
        ]
      end

      def test_get_json_value
        dates.each do |data|
          (input, output) = data
          vcard = Tilia::VObject::Component::VCard.new
          prop = vcard.create_property('BDAY', input)

          assert_equal([output], prop.json_value)
        end
      end

      def test_set_parts
        vcard = Tilia::VObject::Component::VCard.new

        prop = vcard.create_property('BDAY')
        prop.parts = [Time.zone.parse('2014-04-02 18:37:00')]

        assert_equal('20140402T183700Z', prop.value)
      end

      def test_set_parts_too_many
        vcard = Tilia::VObject::Component::VCard.new

        prop = vcard.create_property('BDAY')

        assert_raises(ArgumentError) { prop.parts = [1, 2] }
      end

      def test_set_parts_string
        vcard = Tilia::VObject::Component::VCard.new

        prop = vcard.create_property('BDAY')
        prop.parts = ['20140402T183700Z']

        assert_equal('20140402T183700Z', prop.value)
      end

      def test_set_value_date_time
        vcard = Tilia::VObject::Component::VCard.new

        prop = vcard.create_property('BDAY')
        prop.value = Time.zone.parse('2014-04-02 18:37:00')

        assert_equal('20140402T183700Z', prop.value)
      end

      def test_set_date_time_offset
        vcard = Tilia::VObject::Component::VCard.new

        prop = vcard.create_property('BDAY')
        prop.value = ActiveSupport::TimeZone.new('America/Toronto').parse('2014-04-02 18:37:00')

        assert_equal('20140402T183700-0400', prop.value)
      end

      def test_get_date_time
        datetime = ActiveSupport::TimeZone.new('America/Toronto').parse('2014-04-02 18:37:00')

        vcard = Tilia::VObject::Component::VCard.new
        prop = vcard.create_property('BDAY', datetime)

        dt = prop.date_time
        assert_equal('2014-04-02T18:37:00-04:00', dt.strftime('%FT%T%:z'), "For some reason this one failed. Current default timezone is: #{::Time.zone}")
      end

      def test_get_date
        datetime = Time.zone.parse('2014-04-02')

        vcard = Tilia::VObject::Component::VCard.new
        prop = vcard.create_property('BDAY', datetime, nil, 'DATE')

        assert_equal('DATE', prop.value_type)
        assert_equal('BDAY:20140402', prop.serialize.chomp)
      end

      def test_get_date_incomplete
        datetime = '--0407'

        vcard = Tilia::VObject::Component::VCard.new
        prop = vcard.add('BDAY', datetime)

        dt = prop.date_time
        # Note: if the year changes between the last line and the next line of
        # code, this test may fail.
        #
        # If that happens, head outside and have a drink.
        current = Time.zone.now
        year = current.year

        assert_equal("#{year}0407", dt.strftime('%Y%m%d'))
      end

      def test_get_date_incomplete_from_v_card
        vcard = <<VCF
BEGIN:VCARD
VERSION:4.0
BDAY:--0407
END:VCARD
VCF
        vcard = Tilia::VObject::Reader.read(vcard)
        prop = vcard['BDAY']

        dt = prop.date_time
        # Note: if the year changes between the last line and the next line of
        # code, this test may fail.
        #
        # If that happens, head outside and have a drink.
        current = Time.zone.now
        year = current.year

        assert_equal("#{year}0407", dt.strftime('%Y%m%d'))
      end

      def test_validate
        datetime = '--0407'

        vcard = Tilia::VObject::Component::VCard.new
        prop = vcard.add('BDAY', datetime)

        assert_equal([], prop.validate)
      end

      def test_validate_broken
        datetime = '123'

        vcard = Tilia::VObject::Component::VCard.new
        prop = vcard.add('BDAY', datetime)

        assert_equal(
          [ # Hash in Array!
            'level'   => 3,
            'message' => 'The supplied value (123) is not a correct DATE-AND-OR-TIME property',
            'node'    => prop
          ],
          prop.validate
        )
      end
    end
  end
end
