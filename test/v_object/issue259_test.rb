require 'test_helper'

module Tilia
  module VObject
    # This test is created to handle the issues brought forward by issue 40.
    #
    # https://github.com/fruux/sabre-vobject/issues/40
    class Issue259Test < Minitest::Test
      def test_parsing_jcal_with_until
        jcal_with_until = '["vcalendar",[],[["vevent",[["uid",{},"text","dd1f7d29"],["organizer",{"cn":"robert"},"cal-address","mailto:robert@robert.com"],["dtstart",{"tzid":"Europe/Berlin"},"date-time","2015-10-21T12:00:00"],["dtend",{"tzid":"Europe/Berlin"},"date-time","2015-10-21T13:00:00"],["transp",{},"text","OPAQUE"],["rrule",{},"recur",{"freq":"MONTHLY","until":"2016-01-01T22:00:00Z"}]],[]]]]'
        parser = Parser::Json.new
        parser.input = jcal_with_until

        vcalendar = parser.parse
        event_as_array = vcalendar.select('VEVENT')
        event = event_as_array.first
        rrule_as_array = event.select('RRULE')
        rrule = rrule_as_array.first
        refute_nil(rrule)
        assert_equal(rrule.value, 'FREQ=MONTHLY;UNTIL=20160101T220000Z')
      end
    end
  end
end
