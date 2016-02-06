require 'test_helper'
require 'v_object/fake_component'

module Tilia
  module VObject
    class ComponentTest < Minitest::Test
      def rule_data
        [
          [[], 2],
          [['FOO'], 3],
          [['BAR'], 1],
          [['BAZ'], 1],
          [['BAR', 'BAZ'], 0],
          [['BAR', 'BAZ', 'ZIM'], 0],
          [['BAR', 'BAZ', 'ZIM', 'GIR'], 0],
          [['BAR', 'BAZ', 'ZIM', 'GIR', 'GIR'], 1]
        ]
      end

      def test_iterate
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        sub = comp.create_component('VEVENT')
        comp.add(sub)

        sub = comp.create_component('VTODO')
        comp.add(sub)

        count = 0
        key = nil
        comp.children.each_with_index do |subcomponent, i|
          count += 1
          key = i
          assert_kind_of(Tilia::VObject::Component, subcomponent)
        end

        assert_equal(2, count)
        assert_equal(1, key)
      end

      def test_magic_get
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        sub = comp.create_component('VEVENT')
        comp.add(sub)

        sub = comp.create_component('VTODO')
        comp.add(sub)

        event = comp['vevent']
        assert_kind_of(Tilia::VObject::Component, event)
        assert_equal('VEVENT', event.name)

        assert_nil(comp['vjournal'])
      end

      def test_magic_get_groups
        comp = Tilia::VObject::Component::VCard.new

        sub = comp.create_property('GROUP1.EMAIL', '1@1.com')
        comp.add(sub)

        sub = comp.create_property('GROUP2.EMAIL', '2@2.com')
        comp.add(sub)

        sub = comp.create_property('EMAIL', '3@3.com')
        comp.add(sub)

        emails = comp['email']
        assert_equal(3, emails.size)

        email1 = comp['group1.email']
        assert_equal('EMAIL', email1[0].name)
        assert_equal('GROUP1', email1[0].group)

        email3 = comp['.email']
        assert_equal('EMAIL', email3[0].name)
        assert_nil(email3[0].group)
      end

      def test_magic_isset
        comp = Tilia::VObject::Component::VCalendar.new

        sub = comp.create_component('VEVENT')
        comp.add(sub)

        sub = comp.create_component('VTODO')
        comp.add(sub)

        assert(comp.key?('vevent'))
        assert(comp.key?('vtodo'))
        refute(comp.key?('vjournal'))
      end

      def test_magic_set_scalar
        comp = Tilia::VObject::Component::VCalendar.new
        comp['myProp'] = 'myValue'

        assert_kind_of(Tilia::VObject::Property, comp['MYPROP'])
        assert_equal('myValue', comp['MYPROP'].to_s)
      end

      def test_magic_set_scalar_twice
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        comp['myProp'] = 'myValue'
        comp['myProp'] = 'myValue'

        assert_equal(1, comp.children.size)
        assert_kind_of(Tilia::VObject::Property, comp['MYPROP'])
        assert_equal('myValue', comp['MYPROP'].to_s)
      end

      def test_magic_set_array
        comp = Tilia::VObject::Component::VCalendar.new
        comp['ORG'] = ['Acme Inc', 'Section 9']

        assert_kind_of(Tilia::VObject::Property, comp['ORG'])
        assert_equal(['Acme Inc', 'Section 9'], comp['ORG'].parts)
      end

      def test_magic_set_component
        comp = Tilia::VObject::Component::VCalendar.new

        # Note that 'myProp' is ignored here.
        comp['myProp'] = comp.create_component('VEVENT')

        assert_equal(1, comp.size)

        assert_equal('VEVENT', comp['VEVENT'].name)
      end

      def test_magic_set_twice
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        comp['VEVENT'] = comp.create_component('VEVENT')
        comp['VEVENT'] = comp.create_component('VEVENT')

        assert_equal(1, comp.children.size)

        assert_equal('VEVENT', comp['VEVENT'].name)
      end

      def test_array_access_get
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        event = comp.create_component('VEVENT')
        event['summary'] = 'Event 1'

        comp.add(event)

        event2 = event.clone
        event2['summary'] = 'Event 2'

        comp.add(event2)

        assert_equal(2, comp.children.size)
        assert_kind_of(Tilia::VObject::Component, comp['vevent'][1])
        assert_equal('Event 2', comp['vevent'][1]['summary'].to_s)
      end

      def test_array_access_exists
        comp = Tilia::VObject::Component::VCalendar.new

        event = comp.create_component('VEVENT')
        event['summary'] = 'Event 1'

        comp.add(event)

        event2 = event.clone
        event2['summary'] = 'Event 2'

        comp.add(event2)

        assert(comp['vevent'][0])
        assert(comp['vevent'][1])
      end

      def test_array_access_set
        comp = Tilia::VObject::Component::VCalendar.new
        assert_raises(RuntimeError) { comp[0] = 'hi there' }
      end

      def test_array_access_unset
        comp = Tilia::VObject::Component::VCalendar.new
        assert_raises(RuntimeError) { comp.delete(0) }
      end

      def test_add_scalar
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        comp.add('myprop', 'value')

        assert_equal(1, comp.children.size)

        bla = comp.children[0]

        assert_kind_of(Tilia::VObject::Property, bla)
        assert_equal('MYPROP', bla.name)
        assert_equal('value', bla.to_s)
      end

      def test_add_scalar_params
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        comp.add('myprop', 'value', 'param1' => 'value1')

        assert_equal(1, comp.children.size)

        bla = comp.children[0]

        assert_kind_of(Tilia::VObject::Property, bla)
        assert_equal('MYPROP', bla.name)
        assert_equal('value', bla.to_s)

        assert_equal(1, bla.parameters.size)

        assert_equal('PARAM1', bla.parameters['PARAM1'].name)
        assert_equal('value1', bla.parameters['PARAM1'].value)
      end

      def test_add_component
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        comp.add(comp.create_component('VEVENT'))

        assert_equal(1, comp.children.size)

        assert_equal('VEVENT', comp['VEVENT'].name)
      end

      def test_add_component_twice
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        comp.add(comp.create_component('VEVENT'))
        comp.add(comp.create_component('VEVENT'))

        assert_equal(2, comp.children.size)

        assert_equal('VEVENT', comp['VEVENT'].name)
      end

      def test_add_arg_fail
        comp = Tilia::VObject::Component::VCalendar.new
        assert_raises(ArgumentError) { comp.add(comp.create_component('VEVENT'), 'hello') }
      end

      def test_add_arg_fail2
        comp = Tilia::VObject::Component::VCalendar.new
        assert_raises(ArgumentError) { comp.add([]) }
      end

      def test_magic_unset
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        comp.add(comp.create_component('VEVENT'))

        comp.delete('vevent')

        assert_equal(0, comp.children.size)
      end

      def test_count
        comp = Tilia::VObject::Component::VCalendar.new
        assert_equal(1, comp.count)
      end

      def test_children
        comp = Tilia::VObject::Component::VCalendar.new({}, false)

        # Note that 'myProp' is ignored here.
        comp.add(comp.create_component('VEVENT'))
        comp.add(comp.create_component('VTODO'))

        r = comp.children
        assert_kind_of(Array, r)
        assert_equal(2, r.size)
      end

      def test_get_components
        comp = Tilia::VObject::Component::VCalendar.new

        comp.add(comp.create_property('FOO', 'BAR'))
        comp.add(comp.create_component('VTODO'))

        r = comp.components
        assert_kind_of(Array, r)
        assert_equal(1, r.size)
        assert_equal('VTODO', r[0].name)
      end

      def test_serialize
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        assert_equal("BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n", comp.serialize)
      end

      def test_serialize_children
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        event = comp.add(comp.create_component('VEVENT'))
        event.delete('DTSTAMP')
        event.delete('UID')
        todo = comp.add(comp.create_component('VTODO'))
        todo.delete('DTSTAMP')
        todo.delete('UID')

        str = comp.serialize

        assert_equal("BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nEND:VEVENT\r\nBEGIN:VTODO\r\nEND:VTODO\r\nEND:VCALENDAR\r\n", str)
      end

      def test_serialize_order_comp_and_prop
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        comp.add(event = comp.create_component('VEVENT'))
        comp.add('PROP1', 'BLABLA')
        comp.add('VERSION', '2.0')
        comp.add(comp.create_component('VTIMEZONE'))

        event.delete 'DTSTAMP'
        event.delete 'UID'
        str = comp.serialize

        assert_equal("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPROP1:BLABLA\r\nBEGIN:VTIMEZONE\r\nEND:VTIMEZONE\r\nBEGIN:VEVENT\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n", str)
      end

      def test_another_serialize_order_prop
        prop4s = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']

        comp = Tilia::VObject::Component::VCard.new({}, false)

        comp['SOMEPROP'] = 'FOO'
        comp['ANOTHERPROP'] = 'FOO'
        comp['THIRDPROP'] = 'FOO'
        prop4s.each do |prop4|
          comp.add('PROP4', 'FOO ' + prop4)
        end
        comp['PROPNUMBERFIVE'] = 'FOO'
        comp['PROPNUMBERSIX'] = 'FOO'
        comp['PROPNUMBERSEVEN'] = 'FOO'
        comp['PROPNUMBEREIGHT'] = 'FOO'
        comp['PROPNUMBERNINE'] = 'FOO'
        comp['PROPNUMBERTEN'] = 'FOO'
        comp['VERSION'] = '2.0'
        comp['UID'] = 'FOO'

        str = comp.serialize

        assert_equal("BEGIN:VCARD\r\nVERSION:2.0\r\nSOMEPROP:FOO\r\nANOTHERPROP:FOO\r\nTHIRDPROP:FOO\r\nPROP4:FOO 1\r\nPROP4:FOO 2\r\nPROP4:FOO 3\r\nPROP4:FOO 4\r\nPROP4:FOO 5\r\nPROP4:FOO 6\r\nPROP4:FOO 7\r\nPROP4:FOO 8\r\nPROP4:FOO 9\r\nPROP4:FOO 10\r\nPROPNUMBERFIVE:FOO\r\nPROPNUMBERSIX:FOO\r\nPROPNUMBERSEVEN:FOO\r\nPROPNUMBEREIGHT:FOO\r\nPROPNUMBERNINE:FOO\r\nPROPNUMBERTEN:FOO\r\nUID:FOO\r\nEND:VCARD\r\n", str)
      end

      def test_instantiate_with_children
        comp = Tilia::VObject::Component::VCard.new(
          'ORG' => ['Acme Inc.', 'Section 9'],
          'FN'  => 'Finn The Human'
        )

        assert_equal(['Acme Inc.', 'Section 9'], comp['ORG'].parts)
        assert_equal('Finn The Human', comp['FN'].value)
      end

      def test_instantiate_sub_component
        comp = Tilia::VObject::Component::VCalendar.new
        event = comp.create_component(
          'VEVENT',
          [
            comp.create_property('UID', '12345')
          ]
        )
        comp.add(event)

        assert_equal('12345', comp['VEVENT']['UID'].value)
      end

      def test_remove_by_name
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        comp.add('prop1', 'val1')
        comp.add('prop2', 'val2')
        comp.add('prop2', 'val2')

        comp.remove('prop2')
        refute(comp.key?('prop2'))
        assert(comp.key?('prop1'))
      end

      def test_remove_by_obj
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        comp.add('prop1', 'val1')
        prop = comp.add('prop2', 'val2')

        comp.remove(prop)
        refute(comp.key?('prop2'))
        assert(comp.key?('prop1'))
      end

      def test_remove_not_found
        comp = Tilia::VObject::Component::VCalendar.new({}, false)
        prop = comp.create_property('A', 'B')
        assert_raises(ArgumentError) { comp.remove(prop) }
      end

      def test_validate_rules
        rule_data.each do |data|
          (component_list, error_count) = data
          vcard = Tilia::VObject::Component::VCard.new

          component = Tilia::VObject::FakeComponent.new(vcard, 'Hi', {}, false)
          component_list.each do |v|
            component.add(v, 'Hello.')
          end

          assert_equal(error_count, component.validate.size)
        end
      end

      def test_validate_repair
        vcard = Tilia::VObject::Component::VCard.new

        component = Tilia::VObject::FakeComponent.new(vcard, 'Hi', {}, false)
        component.validate(Tilia::VObject::Component::REPAIR)
        assert_equal('yow', component['BAR'].value)
      end
    end
  end
end
