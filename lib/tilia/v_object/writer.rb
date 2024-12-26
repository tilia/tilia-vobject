require 'json'
module Tilia
  module VObject
    # iCalendar/vCard/jCal/jCard/xCal/xCard writer object.
    #
    # This object provides a few (static) convenience methods to quickly access
    # the serializers.
    class Writer
      # Serializes a vCard or iCalendar object.
      #
      # @param [Component] component
      #
      # @return [String]
      def self.write(component)
        component.serialize
      end

      # Serializes a jCal or jCard object.
      #
      # @param [Component] component
      # @param [Integer] options
      #
      # @return [String]
      def self.write_json(component)
        component.json_serialize.to_json
      end

      # Serializes a xCal or xCard object.
      #
      # @param [Component] component
      #
      # @return [String]
      def self.write_xml(component)
        writer = Tilia::Xml::Writer.new
        writer.open_memory
        writer.set_indent(true)

        writer.start_document(encoding: LibXML::XML::Encoding::UTF_8)

        if component.is_a? Tilia::VObject::Component::VCalendar
          writer.start_element('icalendar')
          writer.write_attribute('xmlns', Tilia::VObject::Parser::Xml::XCAL_NAMESPACE)
        else
          writer.start_element('vcards')
          writer.write_attribute('xmlns', Tilia::VObject::Parser::Xml::XCARD_NAMESPACE)
        end

        component.xml_serialize(writer)

        writer.end_element

        writer.output_memory
      end
    end
  end
end
