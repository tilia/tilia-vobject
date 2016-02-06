require 'test_helper'

module Tilia
  module VObject
    class ByMonthInDailyTest < Minitest::Test
      # This tests the expansion of dates with DAILY frequency in RRULE with BYMONTH restrictions
      def test_expand
        ics = <<ICS
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Apple Inc.//iCal 4.0.4//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
TRANSP:OPAQUE
DTEND:20070925T183000Z
UID:uuid
DTSTAMP:19700101T000000Z
LOCATION:
DESCRIPTION:
STATUS:CONFIRMED
SEQUENCE:18
SUMMARY:Stuff
DTSTART:20070925T160000Z
CREATED:20071004T144642Z
RRULE:FREQ=DAILY;BYMONTH=9,10;BYDAY=SU
END:VEVENT
END:VCALENDAR
ICS
        vcal = Tilia::VObject::Reader.read(ics)
        assert_kind_of(Tilia::VObject::Component::VCalendar, vcal)

        vcal = vcal.expand(Time.zone.parse('2013-09-28'), Time.zone.parse('2014-09-11'))

        dates = []
        vcal['VEVENT'].each do |event|
          dates << event['DTSTART'].value
        end

        expected_dates = [
          '20130929T160000Z',
          '20131006T160000Z',
          '20131013T160000Z',
          '20131020T160000Z',
          '20131027T160000Z',
          '20140907T160000Z'
        ]

        assert_equal(expected_dates, dates, 'Recursed dates are restricted by month')
      end
    end
  end
end
