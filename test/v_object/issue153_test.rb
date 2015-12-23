require 'test_helper'

module Tilia
  module VObject
    class Issue153Test < Minitest::Test
      def test_read
        obj = Tilia::VObject::Reader.read(File.read(File.join(File.dirname(__FILE__), 'issue153.vcf')))
        assert_equal('Test Benutzer', obj['FN'].to_s)
      end
    end
  end
end
