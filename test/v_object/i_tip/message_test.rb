require 'test_helper'

module Tilia
  module VObject
    class MessageTest < Minitest::Test
      def setup
        @message = Tilia::VObject::ITip::Message.new
      end

      def test_no_schedule_status
        refute(@message.schedule_status)
      end

      def test_schedule_status
        @message.schedule_status = '1.2;Delivered'
        assert_equal('1.2', @message.schedule_status)
      end

      def test_unexpected_schedule_status
        @message.schedule_status = '9.9.9'
        assert_equal('9.9.9', @message.schedule_status)
      end
    end
  end
end
