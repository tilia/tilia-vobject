require 'test_helper'

module Tilia
  module VObject
    # Note that most MimeDir related tests can actually be found in the ReaderTest
    # class one level up.
    class MimeDirTest < Minitest::Test
      def test_parse_error
        mime_dir = Tilia::VObject::Parser::MimeDir.new
        assert_raises(Tilia::VObject::ParseException) { mime_dir.parse(File.open(__FILE__)) }
      end
    end
  end
end
