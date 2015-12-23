require 'test_helper'
require 'base64'

module Tilia
  module VObject
    class JCalTest < Minitest::Test
      def test_to_j_cal
        cal = Tilia::VObject::Component::VCalendar.new

        event = cal.add(
          'VEVENT',
          'UID'        => 'foo',
          'DTSTART'    => Time.zone.parse('2013-05-26 18:10:00Z'),
          'DURATION'   => 'P1D',
          'CATEGORIES' => ['home', 'testing'],
          'CREATED'    => Time.zone.parse('2013-05-26 18:10:00Z'),

          'ATTENDEE'     => 'mailto:armin@example.org',
          'GEO'          => [51.96668, 7.61876],
          'SEQUENCE'     => 5,
          'FREEBUSY'     => ['20130526T210213Z/PT1H', '20130626T120000Z/20130626T130000Z'],
          'URL'          => 'http://example.org/',
          'TZOFFSETFROM' => '+0500',
          'RRULE'        => { 'FREQ' => 'WEEKLY', 'BYDAY' => ['MO', 'TU'] }
        )

        # Modifying DTSTART to be a date-only.
        event['DTSTART']['VALUE'] = 'DATE'
        event.add('X-BOOL', true, 'VALUE' => 'BOOLEAN')
        event.add('X-TIME', '08:00:00', 'VALUE' => 'TIME')
        event.add('ATTACH', 'attachment', 'VALUE' => 'BINARY')
        event.add('ATTENDEE', 'mailto:dominik@example.org', 'CN' => 'Dominik', 'PARTSTAT' => 'DECLINED')

        event.add('REQUEST-STATUS', ['2.0', 'Success'])
        event.add('REQUEST-STATUS', ['3.7', 'Invalid Calendar User', 'ATTENDEE:mailto:jsmith@example.org'])

        event.add('DTEND', '20150108T133000')

        expected = [
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
                  'rrule', {}, 'recur', {
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
                  'attach', {}, 'binary', Base64.strict_encode64('attachment')
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
                ],
                [
                  'dtend',
                  {},
                  'date-time',
                  '2015-01-08T13:30:00'
                ]
              ],
              []
            ]
          ]
        ]

        assert_equal(expected, cal.json_serialize)
      end
    end
  end
end
