module Tilia
  module VObject
    # Document.
    #
    # A document is just like a component, except that it's also the top level
    # element.
    #
    # Both a VCALENDAR and a VCARD are considered documents.
    #
    # This class also provides a registry for document types.
    class Document < Component
      # Unknown document type.
      UNKNOWN = 1

      # vCalendar 1.0.
      VCALENDAR10 = 2

      # iCalendar 2.0.
      ICALENDAR20 = 3

      # vCard 2.1.
      VCARD21 = 4

      # vCard 3.0.
      VCARD30 = 5

      # vCard 4.0.
      VCARD40 = 6

      # The default name for this component.
      #
      # This should be 'VCALENDAR' or 'VCARD'.
      #
      # @return [String]
      @default_name = nil

      # List of properties, and which classes they map to.
      #
      # @return [array]
      @property_map = {}

      # List of components, along with which classes they map to.
      #
      # @return [array]
      @component_map = {}

      # List of value-types, and which classes they map to.
      #
      # @return [array]
      @value_map = {}

      class << self
        attr_accessor :default_name
        attr_accessor :property_map
        attr_accessor :component_map
        attr_accessor :value_map
      end

      # Creates a new document.
      #
      # We're changing the default behavior slightly here. First, we don't want
      # to have to specify a name (we already know it), and we want to allow
      # children to be specified in the first argument.
      #
      # But, the default behavior also works.
      #
      # So the two sigs:
      #
      # new Document(array children = [], defaults = true)
      # new Document(string name, array children = [], defaults = true)
      #
      # @return [void]
      def initialize(*args)
        if args.size == 0 || args[0].is_a?(Hash) || args[0].is_a?(Array)
          args.unshift(self.class.default_name)
          args.unshift(self)

          super(*args)
        else
          args.unshift(self)
          super(*args)
        end
      end

      # Returns the current document type.
      #
      # @return [Fixnum]
      def document_type
        UNKNOWN
      end

      # Creates a new component or property.
      #
      # If it's a known component, we will automatically call createComponent.
      # otherwise, we'll assume it's a property and call createProperty instead.
      #
      # @param [String] name
      # @param [String] arg1,... Unlimited number of args
      #
      # @return [mixed]
      def create(name, *args)
        if self.class.component_map.key?(name.upcase)
          create_component(name, *args)
        else
          create_property(name, *args)
        end
      end

      # Creates a new component.
      #
      # This method automatically searches for the correct component class, based
      # on its name.
      #
      # You can specify the children either in key=>value syntax, in which case
      # properties will automatically be created, or you can just pass a list of
      # Component and Property object.
      #
      # By default, a set of sensible values will be added to the component. For
      # an iCalendar object, this may be something like CALSCALE:GREGORIAN. To
      # ensure that this does not happen, set defaults to false.
      #
      # @param [String] name
      # @param [array] children
      # @param [Boolean] defaults
      #
      # @return [Component]
      def create_component(name, children = nil, defaults = true)
        name = name.upcase

        klass = Component

        klass = self.class.component_map[name] if self.class.component_map.key?(name)

        children = [] unless children
        klass.new(self, name, children, defaults)
      end

      # Factory method for creating new properties.
      #
      # This method automatically searches for the correct property class, based
      # on its name.
      #
      # You can specify the parameters either in key=>value syntax, in which case
      # parameters will automatically be created, or you can just pass a list of
      # Parameter objects.
      #
      # @param [String] name
      # @param value
      # @param [array] parameters
      # @param [String] value_type Force a specific valuetype, such as URI or TEXT
      #
      # @return [Property]
      def create_property(name, value = nil, parameters = nil, value_type = nil)
        parameters = {} unless parameters

        # If there's a . in the name, it means it's prefixed by a groupname.
        i = name.index('.')
        if i
          group = name[0...i]
          name = name[i + 1..-1].upcase
        else
          name = name.upcase
          group = nil
        end

        klass = nil

        if value_type
          # The valueType argument comes first to figure out the correct
          # class.
          klass = class_name_for_property_value(value_type)
        end

        unless klass
          # If a VALUE parameter is supplied, we should use that.
          if parameters.key?('VALUE')
            klass = class_name_for_property_value(parameters['VALUE'])
          else
            klass = class_name_for_property_name(name)
          end
        end

        klass.new(self, name, value, parameters, group)
      end

      # This method returns a full class-name for a value parameter.
      #
      # For instance, DTSTART may have VALUE=DATE. In that case we will look in
      # our valueMap table and return the appropriate class name.
      #
      # This method returns null if we don't have a specialized class.
      #
      # @param [String] value_param
      #
      # @return [void]
      def class_name_for_property_value(value_param)
        value_param = value_param.upcase

        return self.class.value_map[value_param] if self.class.value_map.key?(value_param)

        nil
      end

      # Returns the default class for a property name.
      #
      # @param [String] property_name
      #
      # @return [String]
      def class_name_for_property_name(property_name)
        if self.class.property_map.key?(property_name)
          self.class.property_map[property_name]
        else
          Property::Unknown
        end
      end
    end
  end
end
