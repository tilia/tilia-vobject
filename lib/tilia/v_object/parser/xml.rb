module Tilia
  module VObject
    module Parser
      # XML Parser.
      #
      # This parser parses both the xCal and xCard formats.
      class Xml < Parser
        require 'tilia/v_object/parser/xml/element'

        XCAL_NAMESPACE ||= 'urn:ietf:params:xml:ns:icalendar-2.0'
        XCARD_NAMESPACE ||= 'urn:ietf:params:xml:ns:vcard-4.0'

        # The input data.
        #
        # @var array
        # RUBY: attr_accessor :input

        # A pointer/reference to the input.
        #
        # @var array
        # RUBY: attr_accessor :pointer

        # Document, root component.
        #
        # @var Sabre\VObject\Document
        # RUBY: attr_accessor :root

        # Creates the parser.
        #
        # Optionally, it's possible to parse the input stream here.
        #
        # @param mixed input
        # @param int options Any parser options (OPTION constants).
        #
        # @return void
        def initialize(input = nil, options = 0)
          @input = nil
          @pointer = nil
          @root = nil

          options = self.class::OPTION_FORGIVING if options == 0

          super(input, options)
        end

        # Parse xCal or xCard.
        #
        # @param resource|string input
        # @param int options
        #
        # @throws \Exception
        #
        # @return Sabre\VObject\Document
        def parse(input = nil, options = 0)
          self.input = input unless input.nil?
          @options = options if options != 0
          if @input.nil?
            fail Tilia::VObject::EofException, 'End of input stream, or no input supplied'
          end

          case @input['name']
          when "{#{self.class::XCAL_NAMESPACE}}icalendar"
            @root = Tilia::VObject::Component::VCalendar.new({}, false)
            @pointer = @input['value'][0]
            parse_v_calendar_components(@root)
          when "{#{self.class::XCARD_NAMESPACE}}vcards"
            @input['value'].each do |v_card|
              @root = Tilia::VObject::Component::VCard.new({ 'version' => '4.0' }, false)
              @pointer = v_card
              parse_v_card_components(@root)

              # We just parse the first <vcard /> element.
              break
            end
          else
            fail Tilia::VObject::ParseException, 'Unsupported XML standard'
          end

          @root
        end

        protected

        # Parse a xCalendar component.
        #
        # @param Component parent_component
        #
        # @return void
        def parse_v_calendar_components(parent_component)
          components = @pointer['value'] ? @pointer['value'] : []

          components.each do |children|
            case self.class.tag_name(children['name'])
            when 'properties'
              @pointer = children['value']
              parse_properties(parent_component)
            when 'components'
              @pointer = children
              parse_component(parent_component)
            end
          end
        end

        # Parse a xCard component.
        #
        # @param Component parent_component
        #
        # @return void
        def parse_v_card_components(parent_component)
          @pointer = @pointer['value']
          parse_properties(parent_component)
        end

        # Parse xCalendar and xCard properties.
        #
        # @param Component parent_component
        # @param string  property_name_prefix
        #
        # @return void
        def parse_properties(parent_component, property_name_prefix = '')
          properties = @pointer ? @pointer : {}

          properties.each do |xml_property|
            (namespace, tag_name) = Tilia::Xml::Service.parse_clark_notation(xml_property['name'])

            property_name       = tag_name
            property_value      = nil
            property_parameters = {}
            property_type       = 'text'

            # A property which is not part of the standard.
            if namespace != Tilia::VObject::Parser::Xml::XCAL_NAMESPACE && namespace != Tilia::VObject::Parser::Xml::XCARD_NAMESPACE
              property_name = 'xml'
              value = "<#{tag_name} xmlns=\"#{namespace}\""

              xml_property['attributes'].each do |attribute_name, attribute_value|
                value += " #{attribute_name}=\"#{attribute_value.gsub('"', '\\"')}\""
              end
              value += ">#{xml_property['value']}</#{tag_name}>"

              property_value = [value]

              create_property(
                parent_component,
                property_name,
                property_parameters,
                property_type,
                property_value
              )

              next
            end

            # xCard group.
            if property_name == 'group'
              next unless xml_property['attributes'].key?('name')

              @pointer = xml_property['value']
              parse_properties(
                parent_component,
                xml_property['attributes']['name'].upcase + '.'
              )

              next
            end

            # Collect parameters.
            xml_property['value'] = xml_property['value'].map do |xml_property_child|
              if !xml_property_child.is_a?(Hash) || 'parameters' != self.class.tag_name(xml_property_child['name'])
                xml_property_child
              else
                xml_parameters = xml_property_child['value']

                xml_parameters.each do |xml_parameter|
                  property_parameter_values = []

                  xml_parameter['value'].each do |xml_parameter_values|
                    property_parameter_values << xml_parameter_values['value']
                  end

                  property_parameters[self.class.tag_name(xml_parameter['name'])] = property_parameter_values.join(',')
                end

                nil # We will delete this with compact()
              end
            end

            xml_property['value'].compact!

            property_name_extended = (@root.is_a?(Tilia::VObject::Component::VCalendar) ? 'xcal' : 'xcard') + ':' + property_name

            case property_name_extended
            when 'xcal:geo'
              property_type = 'float'
              property_value ||= {}
              property_value['latitude']  = 0.0
              property_value['longitude'] = 0.0

              xml_property['value'].each do |xml_request_child|
                property_value[self.class.tag_name(xml_request_child['name'])] = xml_request_child['value']
              end
            when 'xcal:request-status'
              property_type = 'text'

              property_value ||= {}
              xml_property['value'].each do |xml_request_child|
                property_value[self.class.tag_name(xml_request_child['name'])] = xml_request_child['value']
              end
            when 'xcal:freebusy', 'xcal:categories', 'xcal:resources', 'xcal:exdate'
              property_type = 'freebusy' if property_name_extended == 'xcal:freebusy'
              # We don't break because we only want to set
              # another property type.

              xml_property['value'].each do |special_child|
                property_value ||= {}
                property_value[self.class.tag_name(special_child['name'])] = special_child['value']
              end
            when 'xcal:rdate'
              property_type = 'date-time'
              property_value ||= []

              xml_property['value'].each do |special_child|
                tag_name = self.class.tag_name(special_child['name'])

                if 'period' == tag_name
                  property_parameters['value'] = 'PERIOD'
                  property_value << special_child['value'].values.join('/')
                else
                  property_value << special_child['value']
                end
              end
            else
              property_type  = self.class.tag_name(xml_property['value'][0]['name'])

              property_value ||= []
              xml_property['value'].each do |value|
                property_value << value['value']
              end

              property_parameters['value'] = 'DATE' if 'date' == property_type
            end

            create_property(
              parent_component,
              property_name_prefix + property_name,
              property_parameters,
              property_type,
              property_value
            )
          end
        end

        # Parse a component.
        #
        # @param Component parent_component
        #
        # @return void
        def parse_component(parent_component)
          components = @pointer['value'] ? @pointer['value'] : []

          components.each do |component|
            component_name    = self.class.tag_name(component['name'])
            current_component = @root.create_component(component_name, nil, false)

            @pointer = component
            parse_v_calendar_components(current_component)

            parent_component.add(current_component)
          end
        end

        # Create a property.
        #
        # @param Component parent_component
        # @param string name
        # @param array parameters
        # @param string type
        # @param mixed value
        #
        # @return void
        def create_property(parent_component, name, parameters, type, value)
          property = @root.create_property(name, nil, parameters, type)
          parent_component.add(property)
          property.xml_value = value
        end

        public

        # Sets the input data.
        #
        # @param resource|string input
        #
        # @return void
        def input=(input)
          input = input.readlines.join('') if input.respond_to?(:readlines)

          if input.is_a?(String)
            reader = Tilia::Xml::Reader.new
            reader.element_map["{#{self.class::XCAL_NAMESPACE}}period"] = Tilia::VObject::Parser::Xml::Element::KeyValue
            reader.element_map["{#{self.class::XCAL_NAMESPACE}}recur"] = Tilia::VObject::Parser::Xml::Element::KeyValue
            reader.xml(input)
            input = reader.parse
          end

          @input = input
        end

        protected

        # Get tag name from a Clark notation.
        #
        # @param string clarked_tag_name
        #
        # @return string
        def self.tag_name(clarked_tag_name)
          (_, tag_name) = Tilia::Xml::Service.parse_clark_notation(clarked_tag_name)
          tag_name
        end
      end
    end
  end
end
