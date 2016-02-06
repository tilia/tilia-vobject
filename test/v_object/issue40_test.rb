require 'test_helper'

module Tilia
  module VObject
    # This test is created to handle the issues brought forward by issue 40.
    #
    # https://github.com/fruux/sabre-vobject/issues/40
    class Issue40Test < Minitest::Test
      def test_encode
        card = Tilia::VObject::Component::VCard.new
        card.add('N', ['van der Harten', ['Rene', 'J.'], '', 'Sir', 'R.D.O.N.'], 'SORT-AS' => ['Harten', 'Rene'])

        card.delete('UID')

        expected = [
          'BEGIN:VCARD',
          'VERSION:4.0',
          "PRODID:-//Tilia//Tilia VObject #{Tilia::VObject::Version::VERSION}//EN",
          'N;SORT-AS=Harten,Rene:van der Harten;Rene,J.;;Sir;R.D.O.N.',
          'END:VCARD',
          ''
        ].join("\r\n")

        assert_equal(expected, card.serialize)
      end
    end
  end
end
