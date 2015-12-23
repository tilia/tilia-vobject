require 'test_helper'
require 'base64'
require 'stringio'

module Tilia
  module VObject
    class JsonTest < Minitest::Test
      def test_round_trip_j_card
        input = [
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
              { 'x-param' => [1, 2] },
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
              { 'group' => 'item1' },
              'text',
              '+1 555 123456'
            ],
            [
              'x-ab-label',
              { 'group' => 'item1' },
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

        parser = Tilia::VObject::Parser::Json.new(input.to_json)
        vobj = parser.parse

        result = vobj.serialize
        expected = <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject #{Tilia::VObject::Version::VERSION}//EN
UID:foo
BDAY:1985-04-07
BDAY;X-PARAM=1,2;VALUE=DATE:1979-12-25
BDAY;VALUE=DATE-TIME:1979-12-25T02:00:00
REV:1995-10-31T22:27:10Z
LANG:nl
N:Last;First;Middle;;
item1.TEL:+1 555 123456
item1.X-AB-LABEL:Walkie Talkie
ADR:;;My Street,Left Side,Second Shack;Hometown;PA;18252;U.S.A
X-TRUNCATED;VALUE=DATE:--12-25
X-TIME-LOCAL;VALUE=TIME:12:30:00
X-TIME-UTC;VALUE=TIME:12:30:00Z
X-TIME-OFFSET;VALUE=TIME:12:30:00-08:00
X-TIME-REDUCED;VALUE=TIME:23
X-TIME-TRUNCATED;VALUE=TIME:--30
X-KARMA-POINTS;VALUE=INTEGER:42
X-GRADE;VALUE=FLOAT:1.3
TZ;VALUE=UTC-OFFSET:-0500
END:VCARD
VCF
        assert_equal(expected, result.delete("\r"))
        assert_equal(input, vobj.json_serialize)
      end

      def test_round_trip_j_cal
        input = [
          'vcalendar',
          [
            [
              'version',
              {},
              'text',
              '2.0'
            ],
            [
              'prodid',
              {},
              'text',
              "-//Tilia//Tilia VObject #{Tilia::VObject::Version::VERSION}//EN"
            ],
            [
              'calscale',
              {},
              'text',
              'GREGORIAN'
            ]
          ],
          [
            [
              'vevent',
              [
                [
                  'uid', {}, 'text', 'foo'
                ],
                [
                  'dtstart', {}, 'date', '2013-05-26'
                ],
                [
                  'duration', {}, 'duration', 'P1D'
                ],
                [
                  'categories', {}, 'text', 'home', 'testing'
                ],
                [
                  'created', {}, 'date-time', '2013-05-26T18:10:00Z'
                ],
                [
                  'attach', {}, 'binary', Base64.strict_encode64('attachment')
                ],
                [
                  'attendee', {}, 'cal-address', 'mailto:armin@example.org'
                ],
                [
                  'attendee',
                  {
                    'cn'       => 'Dominik',
                    'partstat' => 'DECLINED'
                  },
                  'cal-address',
                  'mailto:dominik@example.org'
                ],
                [
                  'geo', {}, 'float', [51.96668, 7.61876]
                ],
                [
                  'sequence', {}, 'integer', 5
                ],
                [
                  'freebusy', {}, 'period',  ['2013-05-26T21:02:13', 'PT1H'], ['2013-06-26T12:00:00', '2013-06-26T13:00:00']
                ],
                [
                  'url', {}, 'uri', 'http://example.org/'
                ],
                [
                  'tzoffsetfrom', {}, 'utc-offset', '+05:00'
                ],
                [
                  'rrule',
                  {},
                  'recur',
                  {
                    'freq'  => 'WEEKLY',
                    'byday' => ['MO', 'TU']
                  }
                ],
                [
                  'x-bool', {}, 'boolean', true
                ],
                [
                  'x-time', {}, 'time', '08:00:00'
                ],
                [
                  'request-status',
                  {},
                  'text',
                  ['2.0', 'Success']
                ],
                [
                  'request-status',
                  {},
                  'text',
                  ['3.7', 'Invalid Calendar User', 'ATTENDEE:mailto:jsmith@example.org']
                ]
              ],
              [
                [
                  'valarm',
                  [
                    [
                      'action', {}, 'text', 'DISPLAY'
                    ]
                  ],
                  []
                ]
              ]
            ]
          ]
        ]

        parser = Tilia::VObject::Parser::Json.new(input.to_json)
        vobj = parser.parse
        result = vobj.serialize

        expected = <<VCF
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{Tilia::VObject::Version::VERSION}//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:foo
DTSTART;VALUE=DATE:20130526
DURATION:P1D
CATEGORIES:home,testing
CREATED:20130526T181000Z
ATTACH;VALUE=BINARY:YXR0YWNobWVudA==
ATTENDEE:mailto:armin@example.org
ATTENDEE;CN=Dominik;PARTSTAT=DECLINED:mailto:dominik@example.org
GEO:51.96668;7.61876
SEQUENCE:5
FREEBUSY:20130526T210213/PT1H,20130626T120000/20130626T130000
URL:http://example.org/
TZOFFSETFROM:+0500
RRULE:FREQ=WEEKLY;BYDAY=MO,TU
X-BOOL;VALUE=BOOLEAN:TRUE
X-TIME;VALUE=TIME:08:00:00
REQUEST-STATUS:2.0;Success
REQUEST-STATUS:3.7;Invalid Calendar User;ATTENDEE:mailto:jsmith@example.org
BEGIN:VALARM
ACTION:DISPLAY
END:VALARM
END:VEVENT
END:VCALENDAR
VCF
        assert_equal(expected, result.delete("\r"))

        assert_equal(input, vobj.json_serialize)
      end

      def test_parse_stream_arg
        input = [
          'vcard',
          [
            [
              'FN', {}, 'text', 'foo'
            ]
          ]
        ]

        stream = StringIO.new
        stream.write(input.to_json)
        stream.rewind

        result = Tilia::VObject::Reader.read_json(stream, 0)
        assert_equal('foo', result['FN'].value)
      end

      def test_parse_invalid_data
        json = Tilia::VObject::Parser::Json.new
        input = [
          'vlist',
          [
            [
              'FN', {}, 'text', 'foo'
            ]
          ]
        ]

        assert_raises(Tilia::VObject::ParseException) { json.parse(input.to_json, 0) }
      end
    end
  end
end
