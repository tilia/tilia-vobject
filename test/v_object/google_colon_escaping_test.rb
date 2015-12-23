require 'test_helper'

module Tilia
  module VObject
    # Google produces vcards with a weird escaping of urls.
    #
    # VObject will provide a workaround for this, so end-user still get expected
    # values.
    class GoogleColonEscapingTest < Minitest::Test
      def test_decode
        vcard = <<VCF
BEGIN:VCARD
VERSION:3.0
FN:Evert Pot
N:Pot;Evert;;;
EMAIL;TYPE=INTERNET;TYPE=WORK:evert@fruux.com
BDAY:1985-04-07
item7.URL:http\://www.rooftopsolutions.nl/
END:VCARD
VCF

        vobj = Tilia::VObject::Reader.read(vcard)
        assert_equal('http://www.rooftopsolutions.nl/', vobj['URL'].value)
      end
    end
  end
end
