require 'test_helper'

module Tilia
  module VObject
    class JCardTest < Minitest::Test
      def test_to_j_card
        card = Tilia::VObject::Component::VCard.new(
          'VERSION'          => '4.0',
          'UID'              => 'foo',
          'BDAY'             => '19850407',
          'REV'              => '19951031T222710Z',
          'LANG'             => 'nl',
          'N'                => ['Last', 'First', 'Middle', '', ''],
          'item1.TEL'        => '+1 555 123456',
          'item1.X-AB-LABEL' => 'Walkie Talkie',
          'ADR'              => [
            '',
            '',
            ['My Street', 'Left Side', 'Second Shack'],
            'Hometown',
            'PA',
            '18252',
            'U.S.A'
          ]
        )

        card.add('BDAY', '1979-12-25', 'VALUE' => 'DATE', 'X-PARAM' => [1, 2])
        card.add('BDAY', '1979-12-25T02:00:00', 'VALUE' => 'DATE-TIME')

        card.add('X-TRUNCATED', '--1225', 'VALUE' => 'DATE')
        card.add('X-TIME-LOCAL', '123000', 'VALUE' => 'TIME')
        card.add('X-TIME-UTC', '12:30:00Z', 'VALUE' => 'TIME')
        card.add('X-TIME-OFFSET', '12:30:00-08:00', 'VALUE' => 'TIME')
        card.add('X-TIME-REDUCED', '23', 'VALUE' => 'TIME')
        card.add('X-TIME-TRUNCATED', '--30', 'VALUE' => 'TIME')

        card.add('X-KARMA-POINTS', '42', 'VALUE' => 'INTEGER')
        card.add('X-GRADE', '1.3', 'VALUE' => 'FLOAT')

        card.add('TZ', '-0500', 'VALUE' => 'UTC-OFFSET')

        expected = [
          'vcard',
          [
            [
              'version',
              {},
              'text',
              '4.0'
            ],
            [
              'prodid',
              {},
              'text',
              "-//Tilia//Tilia VObject #{Tilia::VObject::Version::VERSION}//EN"
            ],
            [
              'uid',
              {},
              'text',
              'foo'
            ],
            [
              'bday',
              {},
              'date-and-or-time',
              '1985-04-07'
            ],
            [
              'bday',
              {
                'x-param' => [1, 2]
              },
              'date',
              '1979-12-25'
            ],
            [
              'bday',
              {},
              'date-time',
              '1979-12-25T02:00:00'
            ],
            [
              'rev',
              {},
              'timestamp',
              '1995-10-31T22:27:10Z'
            ],
            [
              'lang',
              {},
              'language-tag',
              'nl'
            ],
            [
              'n',
              {},
              'text',
              ['Last', 'First', 'Middle', '', '']
            ],
            [
              'tel',
              {
                'group' => 'item1'
              },
              'text',
              '+1 555 123456'
            ],
            [
              'x-ab-label',
              {
                'group' => 'item1'
              },
              'unknown',
              'Walkie Talkie'
            ],
            [
              'adr',
              {},
              'text',
              [
                '',
                '',
                ['My Street', 'Left Side', 'Second Shack'],
                'Hometown',
                'PA',
                '18252',
                'U.S.A'
              ]
            ],
            [
              'x-truncated',
              {},
              'date',
              '--12-25'
            ],
            [
              'x-time-local',
              {},
              'time',
              '12:30:00'
            ],
            [
              'x-time-utc',
              {},
              'time',
              '12:30:00Z'
            ],
            [
              'x-time-offset',
              {},
              'time',
              '12:30:00-08:00'
            ],
            [
              'x-time-reduced',
              {},
              'time',
              '23'
            ],
            [
              'x-time-truncated',
              {},
              'time',
              '--30'
            ],
            [
              'x-karma-points',
              {},
              'integer',
              42
            ],
            [
              'x-grade',
              {},
              'float',
              1.3
            ],
            [
              'tz',
              {},
              'utc-offset',
              '-05:00'
            ]
          ]
        ]

        assert_equal(expected, card.json_serialize)
      end
    end
  end
end
