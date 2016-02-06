require 'test_helper'

module Tilia
  module VObject
    # This is a unittest for Issue #53.
    class HandleRDateExpandTest < Minitest::Test
      def test_expand
        input = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:2CD5887F7CF4600F7A3B1F8065099E40-240BDA7121B61224
DTSTAMP;VALUE=DATE-TIME:20151014T110604Z
CREATED;VALUE=DATE-TIME:20151014T110245Z
LAST-MODIFIED;VALUE=DATE-TIME:20151014T110541Z
DTSTART;VALUE=DATE-TIME;TZID=Europe/Berlin:20151012T020000
DTEND;VALUE=DATE-TIME;TZID=Europe/Berlin:20151012T013000
SUMMARY:Test
SEQUENCE:2
RDATE;VALUE=DATE-TIME;TZID=Europe/Berlin:20151015T020000,20151017T020000,20
 151018T020000,20151020T020000
TRANSP:OPAQUE
CLASS:PUBLIC
END:VEVENT
END:VCALENDAR
ICS

        vcal = VObject::Reader.read(input)
        assert_kind_of(Component::VCalendar, vcal)

        vcal = vcal.expand(Time.zone.parse('2015-01-01'), Time.zone.parse('2015-12-01'))

        result = vcal['VEVENT'].to_a

        assert_equal(5, result.size)

        utc = ActiveSupport::TimeZone.new('UTC')
        expected = [
            utc.parse("2015-10-12"),
            utc.parse("2015-10-15"),
            utc.parse("2015-10-17"),
            utc.parse("2015-10-18"),
            utc.parse("2015-10-20"),
        ]

        result = result.map { |ev| ev['DTSTART'].date_time }
        assert_equal(expected, result)
      end
    end
  end
end
