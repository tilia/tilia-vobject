require 'json'
module Tilia
  module VObject
    module Parser
      # Json Parser.
      #
      # This parser parses both the jCal and jCard formats.
      class Json < Parser
        # The input data.
        #
        # @var array
        # RUBY: attr_accessor :input

        # Root component.
        #
        # @var Document
        # RUBY: attr_accessor :root

        # This method starts the parsing process.
        #
        # If the input was not supplied during construction, it's possible to pass
        # it here instead.
        #
        # If either input or options are not supplied, the defaults will be used.
        #
        # @param resource|string|array|null input
        # @param int options
        #
        # @return Sabre\VObject\Document
        def parse(input = nil, options = 0)
          self.input = input unless input.nil?
          if @input.nil?
            fail Tilia::VObject::EofException, 'End of input stream, or no input supplied'
          end

          @options = options if 0 != options

          case @input[0]
          when 'vcalendar'
            @root = Tilia::VObject::Component::VCalendar.new({}, false)
          when 'vcard'
            @root = Tilia::VObject::Component::VCard.new({}, false)
          else
            fail Tilia::VObject::ParseException, 'The root component must either be a vcalendar, or a vcard'
          end

          @input[1].each do |prop|
            @root.add(parse_property(prop))
          end
          if @input[2]
            @input[2].each do |comp|
              @root.add(parse_component(comp))
            end
          end

          # Resetting the input so we can throw an feof exception the next time.
          @input = nil

          @root
        end

        # Parses a component.
        #
        # @param array j_comp
        #
        # @return \Sabre\VObject\Component
        def parse_component(j_comp)
          properties = j_comp[1].map do |j_prop|
            parse_property(j_prop)
          end

          if j_comp[2]
            components = j_comp[2].map do |j|
              parse_component(j)
            end
          else
            components = []
          end

          @root.create_component(
            j_comp[0],
            components + properties,
            false
          )
        end

        # Parses properties.
        #
        # @param array j_prop
        #
        # @return \Sabre\VObject\Property
        def parse_property(j_prop)
          (
              property_name,
              parameters,
              value_type
          ) = j_prop

          property_name = property_name.upcase

          # This is the default class we would be using if we didn't know the
          # value type. We're using this value later in this function.
          default_property_class = @root.class_name_for_property_name(property_name)

          # parameters = (array)parameters

          value = j_prop[3..-1]

          value_type = value_type.upcase

          if parameters.key?('group')
            property_name = parameters['group'] + '.' + property_name
            parameters.delete('group')
          end

          prop = @root.create_property(property_name, nil, parameters, value_type)
          prop.json_value = value

          # We have to do something awkward here. FlatText as well as Text
          # represents TEXT values. We have to normalize these here. In the
          # future we can get rid of FlatText once we're allowed to break BC
          # again.
          if default_property_class == Tilia::VObject::Property::FlatText
            default_property_class = Tilia::VObject::Property::Text
          end

          # If the value type we received (e.g.: TEXT) was not the default value
          # type for the given property (e.g.: BDAY), we need to add a VALUE=
          # parameter.
          prop['VALUE'] = value_type if default_property_class != prop.class

          prop
        end

        # Sets the input data.
        #
        # @param resource|string|array input
        #
        # @return void
        def input=(input)
          input = input.readlines.join('') if input.respond_to?(:readlines)
          input = JSON.parse(input) if input.is_a?(String)

          @input = input
        end
      end
    end
  end
end
