module Tilia
  module VObject
    # Property.
    #
    # A property is always in a KEY:VALUE structure, and may optionally contain
    # parameters.
    class Property < Node
      require 'tilia/v_object/property/binary'
      require 'tilia/v_object/property/boolean'
      require 'tilia/v_object/property/text'
      require 'tilia/v_object/property/flat_text'
      require 'tilia/v_object/property/float_value'
      require 'tilia/v_object/property/integer_value'
      require 'tilia/v_object/property/time'
      require 'tilia/v_object/property/unknown'
      require 'tilia/v_object/property/uri'
      require 'tilia/v_object/property/utc_offset'
      require 'tilia/v_object/property/i_calendar'
      require 'tilia/v_object/property/v_card'

      # Property name.
      #
      # This will contain a string such as DTSTART, SUMMARY, FN.
      #
      # @var string
      attr_accessor :name

      # Property group.
      #
      # This is only used in vcards
      #
      # @var string
      attr_accessor :group

      # List of parameters.
      #
      # @var array
      attr_accessor :parameters

      # Current value.
      #
      # @var mixed
      # RUBY: attr_accessor :value

      # In case this is a multi-value property. This string will be used as a
      # delimiter.
      #
      # @var string|null
      attr_accessor :delimiter

      # Creates the generic property.
      #
      # Parameters must be specified in key=>value syntax.
      #
      # @param Component root The root document
      # @param string name
      # @param string|array|null value
      # @param array parameters List of parameters
      # @param string group The vcard property group
      #
      # @return void
      def initialize(root, name, value = nil, parameters = {}, group = nil)
        @parameters = {}
        @delimiter = ';'
        @name = name
        @group = group
        @root = root

        parameters.each do |k, v|
          add(k, v)
        end

        self.value = value unless value.nil?
      end

      # Updates the current value.
      #
      # This may be either a single, or multiple strings in an array.
      #
      # @param string|array value
      #
      # @return void
      attr_writer :value

      # Returns the current value.
      #
      # This method will always return a singular value. If this was a
      # multi-value object, some decision will be made first on how to represent
      # it as a string.
      #
      # To get the correct multi-value version, use getParts.
      #
      # @return string
      def value
        if @value.is_a?(Array)
          if @value.empty?
            nil
          elsif @value.size == 1
            @value[0]
          else
            raw_mime_dir_value
          end
        else
          @value
        end
      end

      # Sets a multi-valued property.
      #
      # @param array parts
      #
      # @return void
      def parts=(parts)
        @value = parts
      end

      # Returns a multi-valued property.
      #
      # This method always returns an array, if there was only a single value,
      # it will still be wrapped in an array.
      #
      # @return array
      def parts
        if @value.nil?
          []
        elsif @value.is_a?(Array)
          @value.clone
        else
          [@value]
        end
      end

      # Adds a new parameter.
      #
      # If a parameter with same name already existed, the values will be
      # combined.
      # If nameless parameter is added, we try to guess it's name.
      #
      # @param string name
      # @param string|null|array value
      def add(name, value = nil)
        no_name = false
        if name.nil?
          name = Parameter.guess_parameter_name_by_value(value)
          no_name = true
        end

        if @parameters.key?(name.upcase)
          @parameters[name.upcase].add_value(value)
        else
          param = Parameter.new(@root, name, value)
          param.no_name = no_name
          @parameters[param.name] = param
        end
      end

      # Returns an iterable list of children.
      #
      # @return array
      attr_reader :parameters

      # Returns the type of value.
      #
      # This corresponds to the VALUE= parameter. Every property also has a
      # 'default' valueType.
      #
      # @return string
      def value_type
      end

      # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
      #
      # This has been 'unfolded', so only 1 line will be passed. Unescaping is
      # not yet done, but parameters are not included.
      #
      # @param string val
      #
      # @return void
      def raw_mime_dir_value=(_val)
      end

      # Returns a raw mime-dir representation of the value.
      #
      # @return string
      def raw_mime_dir_value
      end

      # Turns the object back into a serialized blob.
      #
      # @return string
      def serialize
        str = @name
        str = "#{@group}.#{@name}" if @group

        parameters.each do |_name, param| # use parameters(), can be overwritten
          str += ";#{param.serialize}"
        end

        str += ":#{raw_mime_dir_value}"

        out = ''
        while str.size > 0
          if str.bytesize > 75
            tmp =  StringUtil.mb_strcut(str, 75)
            out += tmp + "\r\n"
            str = ' ' + str[tmp.length..-1]
          else
            out += str + "\r\n"
            str = ''
            break
          end
        end

        out
      end

      # Returns the value, in the format it should be encoded for JSON.
      #
      # This method must always return an array.
      #
      # @return array
      def json_value
        parts
      end

      # Sets the JSON value, as it would appear in a jCard or jCal object.
      #
      # The value must always be an array.
      #
      # @param array value
      #
      # @return void
      def json_value=(value)
        value = value.values if value.is_a?(Hash)
        if value.size == 1
          self.value = value[0]
        else
          self.value = value
        end
      end

      # This method returns an array, with the representation as it should be
      # encoded in JSON. This is used to create jCard or jCal documents.
      #
      # @return array
      def json_serialize
        parameters = {}

        @parameters.each do |_, parameter|
          next if parameter.name == 'VALUE'

          parameters[parameter.name.downcase] = parameter.json_serialize
        end

        # In jCard, we need to encode the property-group as a separate 'group'
        # parameter.
        parameters['group'] = @group if @group

        result = [
          @name.downcase,
          parameters,
          value_type.downcase
        ]
        result.concat json_value
      end

      # Hydrate data from a XML subtree, as it would appear in a xCard or xCal
      # object.
      #
      # @param array value
      #
      # @return void
      def xml_value=(value)
        self.json_value = value
      end

      # This method serializes the data into XML. This is used to create xCard or
      # xCal documents.
      #
      # @param Xml\Writer writer  XML writer.
      #
      # @return void
      def xml_serialize(writer)
        parameters = []

        @parameters.each do |_, parameter|
          next if parameter.name == 'VALUE'

          parameters << parameter
        end

        writer.start_element(@name.downcase)

        if parameters.any?
          writer.start_element('parameters')

          parameters.each do |parameter|
            writer.start_element(parameter.name.downcase)
            writer.write(parameter)
            writer.end_element
          end

          writer.end_element
        end

        xml_serialize_value(writer)
        writer.end_element
      end

      protected

      # This method serializes only the value of a property. This is used to
      # create xCard or xCal documents.
      #
      # @param Xml\Writer writer  XML writer.
      #
      # @return void
      def xml_serialize_value(writer)
        value_type = self.value_type.downcase

        json_value.each do |values|
          values = [values] unless values.is_a?(Array)
          values.each do |value|
            writer.write_element(value_type, value)
          end
        end
      end

      public

      # Called when this object is being cast to a string.
      #
      # If the property only had a single value, you will get just that. In the
      # case the property had multiple values, the contents will be escaped and
      # combined with ,.
      #
      # @return string
      def to_s
        value.to_s
      end

      # Checks if an array element exists.
      #
      # @param mixed name
      #
      # @return bool
      def key?(name)
        name = name.upcase

        @parameters.each do |_name, parameter|
          return true if parameter.name == name
        end
        false
      end

      # Returns a parameter.
      #
      # If the parameter does not exist, null is returned.
      #
      # @param string name
      #
      # @return Node
      def [](name)
        return super(name) if name.is_a?(Fixnum)

        @parameters[name.upcase]
      end

      # Creates a new parameter.
      #
      # @param string name
      # @param mixed value
      #
      # @return void
      def []=(name, value)
        if name.is_a?(Fixnum)
          super(name, value)
          # @codeCoverageIgnoreStart
          # This will never be reached, because an exception is always
          # thrown.
          return nil
          # @codeCoverageIgnoreEnd
        end

        param = Parameter.new(@root, name, value)
        @parameters[param.name] = param
      end

      # Removes one or more parameters with the specified name.
      #
      # @param string name
      #
      # @return void
      def delete(name)
        if name.is_a?(Fixnum)
          super(name)
          # @codeCoverageIgnoreStart
          # This will never be reached, because an exception is always
          # thrown.
          return nil
          # @codeCoverageIgnoreEnd
        end

        @parameters.delete(name.upcase)
      end

      # This method is automatically called when the object is cloned.
      # Specifically, this will ensure all child elements are also cloned.
      #
      # @return void
      def initialize_copy(_original)
        new_params = {}
        @parameters.each do |key, child|
          new_params[key] = child.clone
          new_params[key].parent = self
        end
        @parameters = new_params
      end

      # Validates the node for correctness.
      #
      # The following options are supported:
      #   - Node::REPAIR - If something is broken, and automatic repair may
      #                    be attempted.
      #
      # An array is returned with warnings.
      #
      # Every item in the array has the following properties:
      #    * level - (number between 1 and 3 with severity information)
      #    * message - (human readable message)
      #    * node - (reference to the offending node)
      #
      # @param int options
      #
      # @return array
      def validate(options = 0)
        warnings = []

        # Checking if our value is UTF-8
        if raw_mime_dir_value.is_a?(String) && !StringUtil.utf8?(raw_mime_dir_value)
          old_value = raw_mime_dir_value
          level = 3

          if options & REPAIR > 0
            new_value = StringUtil.convert_to_utf8(old_value)

            self.raw_mime_dir_value = new_value
            level = 1
          end

          matches = /([\x00-\x08\x0B-\x0C\x0E-\x1F\x7F])/.match(old_value)
          if matches
            message = format('Property contained a control character (0x%02x)', matches[1].ord)
          else
            message = "Property is not valid UTF-8! #{old_value}"
          end

          warnings << {
            'level'   => level,
            'message' => message,
            'node'    => self
          }
        end

        # Checking if the propertyname does not contain any invalid bytes.
        unless @name =~ /^([A-Z0-9-]+)$/
          warnings << {
            'level'   => 1,
            'message' => "The propertyname: #{@name} contains invalid characters. Only A-Z, 0-9 and - are allowed",
            'node'    => self
          }

          if options & REPAIR > 0
            # Uppercasing and converting underscores to dashes.
            @name = @name.upcase.tr('_', '-')

            # Removing every other invalid character
            @name = @name.gsub(/([^A-Z0-9-])/u, '')
          end
        end

        encoding = self['ENCODING']
        if encoding
          if @root.document_type == Document::VCARD40
            warnings << {
              'level'   => 1,
              'message' => 'ENCODING parameter is not valid in vCard 4.',
              'node'    => self
            }
          else
            encoding = encoding.to_s

            allowed_encoding = []

            case @root.document_type
            when Document::ICALENDAR20
              allowed_encoding = ['8BIT', 'BASE64']
            when Document::VCARD21
              allowed_encoding = ['QUOTED-PRINTABLE', 'BASE64', '8BIT']
            when Document::VCARD30
              allowed_encoding = ['B']
            end

            if allowed_encoding.any? && !allowed_encoding.include?(encoding.upcase)
              warnings << {
                'level'   => 1,
                'message' => "ENCODING=#{encoding.upcase} is not valid for this document type.",
                'node'    => self
              }
            end
          end
        end

        # Validating inner parameters
        @parameters.each do |_name, param|
          warnings.concat param.validate(options)
        end

        warnings
      end

      # Call this method on a document if you're done using it.
      #
      # It's intended to remove all circular references, so PHP can easily clean
      # it up.
      #
      # @return void
      def destroy
        super

        @parameters.each do |_name, param|
          param.destroy
        end

        @parameters = {}
      end

      # TODO: document
      def ==(other)
        if other.is_a?(String)
          to_s == other
        else
          super(other)
        end
      end
    end
  end
end
