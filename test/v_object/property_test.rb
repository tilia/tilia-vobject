require 'test_helper'

module Tilia
  module VObject
    class PropertyTest < Minitest::Test
      def test_to_string
        cal = Tilia::VObject::Component::VCalendar.new

        property = cal.create_property('propname', 'propvalue')
        assert_equal('PROPNAME', property.name)
        assert_equal('propvalue', property.to_s)
        assert_equal('propvalue', property.to_s)
        assert_equal('propvalue', property.value)
      end

      def test_create
        cal = Tilia::VObject::Component::VCalendar.new

        params = {
          'param1' => 'value1',
          'param2' => 'value2'
        }

        property = cal.create_property('propname', 'propvalue', params)

        assert_equal('value1', property['param1'].value)
        assert_equal('value2', property['param2'].value)
      end

      def test_set_value
        cal = Tilia::VObject::Component::VCalendar.new

        property = cal.create_property('propname', 'propvalue')
        property.value = 'value2'

        assert_equal('PROPNAME', property.name)
        assert_equal('value2', property.to_s)
      end

      def test_parameter_exists
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'

        assert(property.key?('PARAMNAME'))
        assert(property.key?('paramname'))
        refute(property.key?('foo'))
      end

      def test_parameter_get
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'

        assert_kind_of(Tilia::VObject::Parameter, property['paramname'])
      end

      def test_parameter_not_exists
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'

        assert_nil(property['foo'])
      end

      def test_parameter_multiple
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'
        property.add('paramname', 'paramvalue')

        assert_kind_of(Tilia::VObject::Parameter, property['paramname'])
        assert_equal(2, property['paramname'].parts.size)
      end

      def test_set_parameter_as_string
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'

        assert_equal(1, property.parameters.size)
        assert_kind_of(Tilia::VObject::Parameter, property.parameters['PARAMNAME'])
        assert_equal('PARAMNAME', property.parameters['PARAMNAME'].name)
        assert_equal('paramvalue', property.parameters['PARAMNAME'].value)
      end

      def test_unset_parameter
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        property['paramname'] = 'paramvalue'

        property.delete('PARAMNAME')
        assert_equal(0, property.parameters.size)
      end

      def test_serialize
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')

        assert_equal("PROPNAME:propvalue\r\n", property.serialize)
      end

      def test_serialize_param
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property(
          'propname',
          'propvalue',
          'paramname'  => 'paramvalue',
          'paramname2' => 'paramvalue2'
        )

        assert_equal("PROPNAME;PARAMNAME=paramvalue;PARAMNAME2=paramvalue2:propvalue\r\n", property.serialize)
      end

      def test_serialize_new_line
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('SUMMARY', "line1\nline2")

        assert_equal("SUMMARY:line1\\nline2\r\n", property.serialize)
      end

      def test_serialize_long_line
        cal = Tilia::VObject::Component::VCalendar.new
        value = '!' * 200
        property = cal.create_property('propname', value)

        expected = 'PROPNAME:' + ('!' * 66) + "\r\n " + ('!' * 74) + "\r\n " + ('!' * 60) + "\r\n"

        assert_equal(expected, property.serialize)
      end

      def test_serialize_utf8_line_fold
        cal = Tilia::VObject::Component::VCalendar.new
        value = ('!' * 65) + "\xc3\xa4bla" # inserted umlaut-a
        property = cal.create_property('propname', value)
        expected = 'PROPNAME:' + ('!' * 65) + "\r\n \xc3\xa4bla\r\n"
        assert_equal(expected, property.serialize)
      end

      def test_get_iterator
        cal = Tilia::VObject::Component::VCalendar.new
        it = Tilia::VObject::ElementList.new([])
        property = cal.create_property('propname', 'propvalue')
        property.iterator = it
        assert_equal(it, property.iterator)
      end

      def test_get_iterator_default
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('propname', 'propvalue')
        it = property.iterator
        assert_kind_of(Tilia::VObject::ElementList, it)
        assert_equal(1, it.size)
      end

      def test_add_scalar
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('EMAIL')

        property.add('myparam', 'value')

        assert_equal(1, property.parameters.size)

        assert_kind_of(Tilia::VObject::Parameter, property.parameters['MYPARAM'])
        assert_equal('MYPARAM', property.parameters['MYPARAM'].name)
        assert_equal('value', property.parameters['MYPARAM'].value)
      end

      def test_add_parameter
        cal = Tilia::VObject::Component::VCalendar.new
        prop = cal.create_property('EMAIL')

        prop.add('MYPARAM', 'value')

        assert_equal(1, prop.parameters.size)
        assert_equal('MYPARAM', prop['myparam'].name)
      end

      def test_add_parameter_twice
        cal = Tilia::VObject::Component::VCalendar.new
        prop = cal.create_property('EMAIL')

        prop.add('MYPARAM', 'value1')
        prop.add('MYPARAM', 'value2')

        assert_equal(1, prop.parameters.size)
        assert_equal(2, prop.parameters['MYPARAM'].parts.size)

        assert_equal('MYPARAM', prop['MYPARAM'].name)
      end

      def test_clone
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property('EMAIL', 'value')
        property['FOO'] = 'BAR'

        property2 = property.clone

        property['FOO'] = 'BAZ'
        assert_equal('BAR', property2['FOO'].to_s)
      end

      def test_create_params
        cal = Tilia::VObject::Component::VCalendar.new
        property = cal.create_property(
          'X-PROP',
          'value',
          'param1' => 'value1',
          'param2' => ['value2', 'value3']
        )

        assert_equal(1, property['PARAM1'].parts.size)
        assert_equal(2, property['PARAM2'].parts.size)
      end

      def test_validate_non_utf8
        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('X-PROP', "Bla\x00")
        result = property.validate(Tilia::VObject::Property::REPAIR)

        assert_equal('Property contained a control character (0x00)', result[0]['message'])
        assert_equal('Bla', property.value)
      end

      def test_validate_control_chars
        s = 'chars['
        [
          0x7F, 0x5E, 0x5C, 0x3B, 0x3A, 0x2C, 0x22, 0x20,
          0x1F, 0x1E, 0x1D, 0x1C, 0x1B, 0x1A, 0x19, 0x18,
          0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10,
          0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08,
          0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00
        ].each do |c|
          s += format('%02X(%c)', c, c)
        end
        s += ']end'

        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('X-PROP', s)
        result = property.validate(Tilia::VObject::Property::REPAIR)

        assert_equal('Property contained a control character (0x7f)', result[0]['message'])
        assert_equal("chars[7F()5E(^)5C(\\\\)3B(\\;)3A(:)2C(\\,)22(\")20( )1F()1E()1D()1C()1B()1A()19()18()17()16()15()14()13()12()11()10()0F()0E()0D()0C()0B()0A(\\n)09(\t)08()07()06()05()04()03()02()01()00()]end", property.raw_mime_dir_value)
      end

      def test_validate_bad_property_name
        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('X_*&PROP*', 'Bla')
        result = property.validate(Tilia::VObject::Property::REPAIR)

        assert_equal(result[0]['message'], 'The propertyname: X_*&PROP* contains invalid characters. Only A-Z, 0-9 and - are allowed')
        assert_equal('X-PROP', property.name)
      end

      def test_get_value
        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('SUMMARY', nil)
        assert_equal([], property.parts)
        assert_nil(property.value)

        property.value = []
        assert_equal([], property.parts)
        assert_nil(property.value)

        property.value = [1]
        assert_equal([1], property.parts)
        assert_equal(1, property.value)

        property.value = [1, 2]
        assert_equal([1, 2], property.parts)
        assert_equal('1,2', property.value)

        property.value = 'str'
        assert_equal(['str'], property.parts)
        assert_equal('str', property.value)
      end

      def test_array_access_set_int
        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('X-PROP', nil)

        calendar.add(property)
        assert_raises(RuntimeError) { calendar['X-PROP'][0] = 'Something!' }
      end

      def test_array_access_unset_int
        calendar = Tilia::VObject::Component::VCalendar.new
        property = calendar.create_property('X-PROP', nil)

        calendar.add(property)
        assert_raises(RuntimeError) { calendar['X-PROP'].delete(0) }
      end

      def test_validate_bad_encoding
        document = Tilia::VObject::Component::VCalendar.new
        property = document.add('X-FOO', 'value')
        property['ENCODING'] = 'invalid'

        result = property.validate
        assert_equal('ENCODING=INVALID is not valid for this document type.', result[0]['message'])
        assert_equal(1, result[0]['level'])
      end

      def test_validate_bad_encoding_v_card4
        document = Tilia::VObject::Component::VCard.new('VERSION' => '4.0')
        property = document.add('X-FOO', 'value')
        property['ENCODING'] = 'BASE64'

        result = property.validate

        assert_equal('ENCODING parameter is not valid in vCard 4.', result[0]['message'])
        assert_equal(1, result[0]['level'])
      end

      def test_validate_bad_encoding_v_card3
        document = Tilia::VObject::Component::VCard.new('VERSION' => '3.0')
        property = document.add('X-FOO', 'value')
        property['ENCODING'] = 'BASE64'

        result = property.validate

        assert_equal('ENCODING=BASE64 is not valid for this document type.', result[0]['message'])
        assert_equal(1, result[0]['level'])
      end

      def test_validate_bad_encoding_v_card21
        document = Tilia::VObject::Component::VCard.new('VERSION' => '2.1')
        property = document.add('X-FOO', 'value')
        property['ENCODING'] = 'B'

        result = property.validate

        assert_equal('ENCODING=B is not valid for this document type.', result[0]['message'])
        assert_equal(1, result[0]['level'])
      end
    end
  end
end
