require 'test_helper'

module Tilia
  module VObject
    class UUIDUtilTest < Minitest::Test
      def test_validate_uuid
        assert(Tilia::VObject::UuidUtil.validate_uuid('11111111-2222-3333-4444-555555555555'))
        refute(Tilia::VObject::UuidUtil.validate_uuid(' 11111111-2222-3333-4444-555555555555'))
        assert(Tilia::VObject::UuidUtil.validate_uuid('ffffffff-2222-3333-4444-555555555555'))
        refute(Tilia::VObject::UuidUtil.validate_uuid('fffffffg-2222-3333-4444-555555555555'))
      end

      def test_get_uuid
        assert(Tilia::VObject::UuidUtil.validate_uuid(Tilia::VObject::UuidUtil.uuid))
      end
    end
  end
end
