require 'test_helper'

module Tilia
  module VObject
    class ParameterTest < Minitest::Test
      def test_setup
        cal = Tilia::VObject::Component::VCalendar.new

        param = Tilia::VObject::Parameter.new(cal, 'name', 'value')
        assert_equal('NAME', param.name)
        assert_equal('value', param.value)
      end

      def test_setup_name_less
        card = Tilia::VObject::Component::VCard.new

        param = Tilia::VObject::Parameter.new(card, nil, 'URL')
        assert_equal('VALUE', param.name)
        assert_equal('URL', param.value)
        assert(param.no_name)
      end

      def test_modify
        cal = Tilia::VObject::Component::VCalendar.new

        param = Tilia::VObject::Parameter.new(cal, 'name', nil)
        param.add_value(1)
        assert_equal([1], param.parts)

        param.parts = [1, 2]
        assert_equal([1, 2], param.parts)

        param.add_value(3)
        assert_equal([1, 2, 3], param.parts)

        param.value = 4
        param.add_value(5)
        assert_equal([4, 5], param.parts)
      end

      def test_cast_to_string
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', 'value')
        assert_equal('value', param.to_s)
        assert_equal('value', param.to_s)
      end

      def test_cast_null_to_string
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', nil)
        assert_equal('', param.to_s)
        assert_equal('', param.to_s)
      end

      def test_serialize
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', 'value')
        assert_equal('NAME=value', param.serialize)
      end

      def test_serialize_empty
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', nil)
        assert_equal('NAME=', param.serialize)
      end

      def test_serialize_complex
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', ['val1', 'val2;', 'val3^', "val4\n", "val5\""])
        assert_equal('NAME=val1,"val2;","val3^^","val4^n","val5^\'"', param.serialize)
      end

      # iCal 7.0 (OSX 10.9) has major issues with the EMAIL property, when the
      # value contains a plus sign, and it's not quoted.
      #
      # So we specifically added support for that.
      def test_serialize_plus_sign
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'EMAIL', 'user+something@example.org')
        assert_equal('EMAIL="user+something@example.org"', param.serialize)
      end

      def test_iterate
        cal = Tilia::VObject::Component::VCalendar.new

        param = Tilia::VObject::Parameter.new(cal, 'name', [1, 2, 3, 4])
        result = []

        param.each do |value|
          result << value
        end

        assert_equal([1, 2, 3, 4], result)
      end

      def test_serialize_colon
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', 'va:lue')
        assert_equal('NAME="va:lue"', param.serialize)
      end

      def test_serialize_semi_colon
        cal = Tilia::VObject::Component::VCalendar.new
        param = Tilia::VObject::Parameter.new(cal, 'name', 'va;lue')
        assert_equal('NAME="va;lue"', param.serialize)
      end
    end
  end
end
