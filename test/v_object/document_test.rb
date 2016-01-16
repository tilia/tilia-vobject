require 'test_helper'
require 'v_object/mock_document'

module Tilia
  module VObject
    class DocumentTest < Minitest::Test
      def test_get_document_type
        doc = Tilia::VObject::MockDocument.new
        assert_equal(Tilia::VObject::Document::UNKNOWN, doc.document_type)
      end

      def test_construct
        doc = Tilia::VObject::MockDocument.new('VLIST')
        assert_equal('VLIST', doc.name)
      end

      def test_create_component
        vcal = Tilia::VObject::Component::VCalendar.new({}, false)

        event = vcal.create_component('VEVENT')

        assert_kind_of(Tilia::VObject::Component::VEvent, event)
        vcal.add(event)

        prop = vcal.create_property('X-PROP', '1234256', 'X-PARAM' => '3')
        assert_kind_of(Tilia::VObject::Property, prop)

        event.add(prop)

        event.delete('DTSTAMP')
        event.delete('UID')

        out = vcal.serialize
        assert_equal("BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nX-PROP;X-PARAM=3:1234256\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n", out)
      end

      def test_create
        vcal = Tilia::VObject::Component::VCalendar.new({}, false)

        event = vcal.create('VEVENT')
        assert_kind_of(Tilia::VObject::Component::VEvent, event)

        prop = vcal.create('CALSCALE')
        assert_kind_of(Tilia::VObject::Property::Text, prop)
      end

      def test_get_class_name_for_property_value
        vcal = Tilia::VObject::Component::VCalendar.new({}, false)
        assert_equal(Tilia::VObject::Property::Text, vcal.class_name_for_property_value('TEXT'))
        assert_nil(vcal.class_name_for_property_value('FOO'))
      end

      def test_destroy
        vcal = Tilia::VObject::Component::VCalendar.new({}, false)
        event = vcal.create_component('VEVENT')

        assert_kind_of(Tilia::VObject::Component::VEvent, event)
        vcal.add(event)

        prop = vcal.create_property('X-PROP', '1234256', 'X-PARAM' => '3')

        event.add(prop)
        assert_equal(event, prop.parent)

        vcal.destroy

        assert_nil(prop.parent)
      end
    end
  end
end
