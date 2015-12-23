require 'test_helper'

module Tilia
  module VObject
    class AttachParseTest < Minitest::Test
      # See issue #128 for more info.
      def test_parse_attach
        vcal = <<ICS
BEGIN:VCALENDAR
BEGIN:VEVENT
ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/reports/r-960812.ps
END:VEVENT
END:VCALENDAR
ICS

        vcal = Tilia::VObject::Reader.read(vcal)
        prop = vcal['VEVENT']['ATTACH']

        assert_kind_of(Tilia::VObject::Property::Uri, prop)
        assert_equal('ftp://example.com/pub/reports/r-960812.ps', prop.value)
      end
    end
  end
end
