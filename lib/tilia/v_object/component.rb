module Tilia
  module VObject
    # Component.
    #
    # A component represents a group of properties, such as VCALENDAR, VEVENT, or
    # VCARD.
    class Component < Node
      require 'tilia/v_object/component/available'
      require 'tilia/v_object/component/v_alarm'
      require 'tilia/v_object/component/v_availability'
      require 'tilia/v_object/component/v_event'
      require 'tilia/v_object/component/v_free_busy'
      require 'tilia/v_object/component/v_journal'
      require 'tilia/v_object/component/v_time_zone'
      require 'tilia/v_object/component/v_todo'
      require 'tilia/v_object/document'
      require 'tilia/v_object/component/v_calendar'
      require 'tilia/v_object/component/v_card'

      # Component name.
      #
      # This will contain a string such as VEVENT, VTODO, VCALENDAR, VCARD.
      #
      # @var string
      attr_accessor :name

      # A list of properties and/or sub-components.
      #
      # @var array
      # RUBY: attr_accessor :children

      # Creates a new component.
      #
      # You can specify the children either in key=>value syntax, in which case
      # properties will automatically be created, or you can just pass a list of
      # Component and Property object.
      #
      # By default, a set of sensible values will be added to the component. For
      # an iCalendar object, this may be something like CALSCALE:GREGORIAN. To
      # ensure that this does not happen, set defaults to false.
      #
      # @param Document root
      # @param string name such as VCALENDAR, VEVENT.
      # @param array children
      # @param bool defaults
      #
      # @return void
      def initialize(root, name, children = {}, defaults = true)
        @children = {}
        @name = name.to_s.upcase
        @root = root

        # Try to handle some PHP quirks
        if children.is_a?(Array)
          new_children = {}
          children.each_with_index { |c, i| new_children[i] = c }
          children = new_children
        end

        if defaults
          # This is a terribly convoluted way to do this, but this ensures
          # that the order of properties as they are specified in both
          # defaults and the childrens list, are inserted in the object in a
          # natural way.
          list = self.defaults
          nodes = []

          children.each do |key, value|
            if value.is_a?(Node)
              list.delete value.name if list.key?(value.name)
              nodes << value
            else
              list[key] = value
            end
          end

          list.each do |key, value|
            add(key, value)
          end

          nodes.each do |node|
            add(node)
          end
        else
          children.each do |k, child|
            if child.is_a?(Node)
              # Component or Property
              add(child)
            else
              # Property key=>value
              add(k, child)
            end
          end
        end
      end

      # Adds a new property or component, and returns the new item.
      #
      # This method has 3 possible signatures:
      #
      # add(Component comp) // Adds a new component
      # add(Property prop)  // Adds a new property
      # add(name, value, array parameters = []) // Adds a new property
      # add(name, array children = []) // Adds a new component
      # by name.
      #
      # @return Node
      def add(*arguments)
        if arguments[0].is_a?(Node)
          if arguments[1]
            fail ArgumentError, 'The second argument must not be specified, when passing a VObject Node'
          end
          arguments[0].parent = self
          new_node = arguments[0]
        elsif arguments[0].is_a?(String)
          new_node = @root.create(*arguments)
        else
          fail ArgumentError, 'The first argument must either be a Node or a string'
        end

        name = new_node.name
        if @children.key?(name)
          @children[name] << new_node
        else
          @children[name] = [new_node]
        end

        new_node
      end

      # This method removes a component or property from this component.
      #
      # You can either specify the item by name (like DTSTART), in which case
      # all properties/components with that name will be removed, or you can
      # pass an instance of a property or component, in which case only that
      # exact item will be removed.
      #
      # @param string|Property|Component item
      # @return void
      def remove(item)
        if item.is_a?(String)
          # If there's no dot in the name, it's an exact property name and
          # we can just wipe out all those properties.
          #
          unless item.index('.')
            @children.delete(item.upcase)
            return nil
          end

          # If there was a dot, we need to ask select to help us out and
          # then we just call remove recursively.
          select(item).each do |child|
            remove(child)
          end
        else
          select(item.name).each_with_index do |child, _k|
            if child == item
              @children[item.name].delete(item)
              return nil
            end
          end
        end

        fail ArgumentError, 'The item you passed to remove was not a child of this component'
      end

      # Returns a flat list of all the properties and components in this
      # component.
      #
      # @return array
      def children
        result = []
        @children.each do |_, child_group|
          result.concat(child_group)
        end

        result
      end

      # This method only returns a list of sub-components. Properties are
      # ignored.
      #
      # @return array
      def components
        result = []

        @children.each do |_key, child_group|
          child_group.each do |child|
            result << child if child.is_a?(Component)
          end
        end

        result
      end

      # Returns an array with elements that match the specified name.
      #
      # This function is also aware of MIME-Directory groups (as they appear in
      # vcards). This means that if a property is grouped as "HOME.EMAIL", it
      # will also be returned when searching for just "EMAIL". If you want to
      # search for a property in a specific group, you can select on the entire
      # string ("HOME.EMAIL"). If you want to search on a specific property that
      # has not been assigned a group, specify ".EMAIL".
      #
      # @param string name
      # @return array
      def select(name)
        group = nil
        name = name.upcase

        (group, name) = name.split('.', 2) if name.index('.')

        name = nil if name.blank?

        if name
          result = @children.key?(name) ? @children[name] : []

          if group.nil?
            return result
          else
            # If we have a group filter as well, we need to narrow it down
            # more.
            return result.select do |child|
              child.is_a?(Property) && (child.group || '').upcase == group
            end
          end
        end

        # If we got to this point, it means there was no 'name' specified for
        # searching, implying that this is a group-only search.
        result = []
        @children.each do |_, child_group|
          child_group.each do |child|
            if child.is_a?(Property) && (child.group || '').upcase == group
              result << child
            end
          end
        end

        result
      end

      # Turns the object back into a serialized blob.
      #
      # @return string
      def serialize
        str = "BEGIN:#{@name}\r\n"

        # Gives a component a 'score' for sorting purposes.
        #
        # This is solely used by the childrenSort method.
        #
        # A higher score means the item will be lower in the list.
        # To avoid score collisions, each "score category" has a reasonable
        # space to accomodate elements. The key is added to the score to
        # preserve the original relative order of elements.
        #
        # @param int key
        # @param array array
        #
        # @return int
        sort_score = lambda do |key, array|
          key = array.index(key)
          if array[key].is_a?(Component)
            # We want to encode VTIMEZONE first, this is a personal
            # preference.
            if array[key].name == 'VTIMEZONE'
              score = 300_000_000
              return score + key
            else
              score = 400_000_000
              return score + key
            end
          else
            # Properties get encoded first
            # VCARD version 4.0 wants the VERSION property to appear first
            if array[key].is_a?(Property)
              if array[key].name == 'VERSION'
                score = 100_000_000
                return score + key
              else
                # All other properties
                score = 200_000_000
                return score + key
              end
            end
          end
        end

        tmp = children.sort do |a, b|
          s_a = sort_score.call(a, children)
          s_b = sort_score.call(b, children)
          s_a - s_b
        end

        tmp.each do |child|
          str += child.serialize
        end
        str += "END:#{@name}\r\n"

        str
      end

      # This method returns an array, with the representation as it should be
      # encoded in JSON. This is used to create jCard or jCal documents.
      #
      # @return array
      def json_serialize
        components = []
        properties = []

        @children.each do |_, child_group|
          child_group.each do |child|
            if child.is_a?(Component)
              components << child.json_serialize
            else
              properties << child.json_serialize
            end
          end
        end

        [
          @name.downcase,
          properties,
          components
        ]
      end

      # This method serializes the data into XML. This is used to create xCard or
      # xCal documents.
      #
      # @param Xml\Writer writer  XML writer.
      #
      # @return void
      def xml_serialize(writer)
        components = []
        properties = []

        @children.each do |_, child_group|
          child_group.each do |child|
            if child.is_a?(Component)
              components << child
            else
              properties << child
            end
          end
        end

        writer.start_element(@name.downcase)

        if properties.any?
          writer.start_element('properties')
          properties.each do |property|
            property.xml_serialize(writer)
          end
          writer.end_element
        end

        if components.any?
          writer.start_element('components')
          components.each do |component|
            component.xml_serialize(writer)
          end
          writer.end_element
        end

        writer.end_element
      end

      protected

      # This method should return a list of default property values.
      #
      # @return array
      def defaults
        []
      end

      public

      # Using 'get' you will either get a property or component.
      #
      # If there were no child-elements found with the specified name,
      # null is returned.
      #
      # To use this, this may look something like this:
      #
      # event = calendar->VEVENT
      #
      # @param string name
      #
      # @return Property
      def [](name)
        return super(name) if name.is_a?(Fixnum)

        if name == 'children'
          fail 'Starting sabre/vobject 4.0 the children property is now protected. You should use the children method instead'
        end

        matches = select(name)

        if matches.empty?
          return nil
        else
          first_match = matches.first
          # @var first_match Property
          first_match.iterator = ElementList.new(matches.to_a)
          return first_match
        end
      end

      # This method checks if a sub-element with the specified name exists.
      #
      # @param string name
      #
      # @return bool
      def key?(name)
        matches = select(name)
        matches.any?
      end

      # Using the setter method you can add properties or subcomponents.
      #
      # You can either pass a Component, Property
      # object, or a string to automatically create a Property.
      #
      # If the item already exists, it will be removed. If you want to add
      # a new item with the same name, always use the add method.
      #
      # @param string name
      # @param mixed value
      #
      # @return void
      def []=(name, value)
        return super(name, value) if name.is_a?(Fixnum)
        name = name.upcase

        remove(name)

        if value.is_a?(Component) || value.is_a?(Property)
          add(value)
        else
          add(name, value)
        end
      end

      # Removes all properties and components within this component with the
      # specified name.
      #
      # @param string name
      #
      # @return void
      def delete(name)
        return super(name) if name.is_a?(Fixnum)
        remove(name)
      end

      # This method is automatically called when the object is cloned.
      # Specifically, this will ensure all child elements are also cloned.
      #
      # @return void
      def initialize_copy(_original)
        new_children = {}
        @children.each do |child_name, child_group|
          new_children[child_name] = []
          child_group.each do |child|
            cloned_child = child.clone
            cloned_child.parent = self
            # cloned_child.root = @root
            new_children[child_name] << cloned_child
          end
        end
        @children = new_children
      end

      # A simple list of validation rules.
      #
      # This is simply a list of properties, and how many times they either
      # must or must not appear.
      #
      # Possible values per property:
      #   * 0 - Must not appear.
      #   * 1 - Must appear exactly once.
      #   * + - Must appear at least once.
      #   * * - Can appear any number of times.
      #   * ? - May appear, but not more than once.
      #
      # It is also possible to specify defaults and severity levels for
      # violating the rule.
      #
      # See the VEVENT implementation for getValidationRules for a more complex
      # example.
      #
      # @var array
      def validation_rules
        []
      end

      # Validates the node for correctness.
      #
      # The following options are supported:
      #   Node::REPAIR - May attempt to automatically repair the problem.
      #   Node::PROFILE_CARDDAV - Validate the vCard for CardDAV purposes.
      #   Node::PROFILE_CALDAV - Validate the iCalendar for CalDAV purposes.
      #
      # This method returns an array with detected problems.
      # Every element has the following properties:
      #
      #  * level - problem level.
      #  * message - A human-readable string describing the issue.
      #  * node - A reference to the problematic node.
      #
      # The level means:
      #   1 - The issue was repaired (only happens if REPAIR was turned on).
      #   2 - A warning.
      #   3 - An error.
      #
      # @param int options
      #
      # @return array
      def validate(options = 0)
        rules = validation_rules
        defaults = self.defaults

        property_counters = {}

        messages = []

        children.each do |child|
          name = child.name.upcase

          if !property_counters.key?(name)
            property_counters[name] = 1
          else
            property_counters[name] += 1
          end
          messages.concat child.validate(options)
        end

        rules.each do |prop_name, rule|
          case rule.to_s
          when '0'
            if property_counters.key?(prop_name)
              messages << {
                'level'   => 3,
                'message' => "#{prop_name} MUST NOT appear in a #{@name} component",
                'node'    => self
              }
            end
          when '1'
            if !property_counters.key?(prop_name) || property_counters[prop_name] != 1
              repaired = false
              add(prop_name, defaults[prop_name]) if options & REPAIR > 0 && defaults.key?(prop_name)

              messages << {
                'level'   => repaired ? 1 : 3,
                'message' => "#{prop_name} MUST appear exactly once in a #{@name} component",
                'node'    => self
              }
            end
          when '+'
            if !property_counters.key?(prop_name) || property_counters[prop_name] < 1
              messages << {
                'level'   => 3,
                'message' => "#{prop_name} MUST appear at least once in a #{@name} component",
                'node'    => self
              }
            end
          when '*'
          when '?'
            if property_counters.key?(prop_name) && property_counters[prop_name] > 1
              messages << {
                'level'   => 3,
                'message' => "#{prop_name} MUST NOT appear more than once in a #{@name} component",
                'node'    => self
              }
            end
          end
        end

        messages
      end

      # Call this method on a document if you're done using it.
      #
      # It's intended to remove all circular references, so PHP can easily clean
      # it up.
      #
      # @return void
      def destroy
        super

        @children.each do |_child_name, child_group|
          child_group.each(&:destroy)
        end

        @children = {}
      end

      # TODO: document
      def to_s
        serialize
      end
    end
  end
end
