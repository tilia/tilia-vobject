require 'test_helper'

module Tilia
  module VObject
    class IssueUndefinedIndexTest < Minitest::Test
      def test_read
        input = <<VCF
BEGIN:VCARD
VERSION:3.0
PRODID:foo
N:Holmes;Sherlock;;;
FN:Sherlock Holmes
ORG:Acme Inc
ADR;type=WORK;type=pref:;;,
\\n221B,Baker Street;London;;12345;United Kingdom
UID:foo
END:VCARD
VCF

        assert_raises(Tilia::VObject::ParseException) { Tilia::VObject::Reader.read(input, Tilia::VObject::Reader::OPTION_FORGIVING) }
      end
    end
  end
end
