module Tilia
  module VObject
    # VObject Parameter.
    #
    # This class represents a parameter. A parameter is always tied to a property.
    # In the case of:
    #   DTSTART;VALUE=DATE:20101108
    # VALUE=DATE would be the parameter name and value.
    class Parameter < Node
      # Parameter name.
      #
      # @var string
      attr_accessor :name

      # vCard 2.1 allows parameters to be encoded without a name.
      #
      # We can deduce the parameter name based on it's value.
      #
      # @var bool
      attr_accessor :no_name

      # Parameter value.
      #
      # @var string
      # RUBY: attr_accessor :value

      # Sets up the object.
      #
      # It's recommended to use the create:: factory method instead.
      #
      # @param string name
      # @param string value
      def initialize(root, name, value = nil)
        @no_name = false
        @name = (name || '').upcase
        @root = root

        if name.nil?
          @no_name = true
          @name = self.class.guess_parameter_name_by_value(value)
        else
          @name = name.upcase
        end

        # If guess_parameter_name_by_value returns an empty string
        # above, we're actually dealing with a parameter that has no value.
        # In that case we have to move the value to the name.
        if @name == ''
          @no_name = false
          @name = value.upcase
        else
          self.value = value
        end
      end

      # Try to guess property name by value, can be used for vCard 2.1 nameless parameters.
      #
      # Figuring out what the name should have been. Note that a ton of
      # these are rather silly in 2014 and would probably rarely be
      # used, but we like to be complete.
      #
      # @param string value
      #
      # @return string
      def self.guess_parameter_name_by_value(value)
        value ||= ''
        case value.upcase
        # Encodings
        when '7-BIT',
            'QUOTED-PRINTABLE',
            'BASE64'
          'ENCODING'
        # Common types
        when 'WORK',
            'HOME',
            'PREF',

            # Delivery Label Type
            'DOM',
            'INTL',
            'POSTAL',
            'PARCEL',

            # Telephone types
            'VOICE',
            'FAX',
            'MSG',
            'CELL',
            'PAGER',
            'BBS',
            'MODEM',
            'CAR',
            'ISDN',
            'VIDEO',

            # EMAIL types (lol)
            'AOL',
            'APPLELINK',
            'ATTMAIL',
            'CIS',
            'EWORLD',
            'INTERNET',
            'IBMMAIL',
            'MCIMAIL',
            'POWERSHARE',
            'PRODIGY',
            'TLX',
            'X400',

            # Photo / Logo format types
            'GIF',
            'CGM',
            'WMF',
            'BMP',
            'DIB',
            'PICT',
            'TIFF',
            'PDF',
            'PS',
            'JPEG',
            'MPEG',
            'MPEG2',
            'AVI',
            'QTIME',

            # Sound Digital Audio Type
            'WAVE',
            'PCM',
            'AIFF',

            # Key types
            'X509',
            'PGP'
          'TYPE'

        # Value types
        when 'INLINE',
            'URL',
            'CONTENT-ID',
            'CID'
          'VALUE'
        else
          ''
        end
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
      # This method will always return a string, or null. If there were multiple
      # values, it will automatically concatenate them (separated by comma).
      #
      # @return string|null
      def value
        if @value.is_a?(Array)
          @value.join(',')
        else
          @value
        end
      end

      # Sets multiple values for this parameter.
      #
      # @param array value
      #
      # @return void
      def parts=(value)
        @value = value
      end

      # Returns all values for this parameter.
      #
      # If there were no values, an empty array will be returned.
      #
      # @return array
      def parts
        if @value.is_a?(Array)
          @value
        elsif @value.nil?
          []
        else
          [@value]
        end
      end

      # Adds a value to this parameter.
      #
      # If the argument is specified as an array, all items will be added to the
      # parameter value list.
      #
      # @param string|array part
      #
      # @return void
      def add_value(part)
        if @value.nil?
          @value = part
        else
          @value = [@value] unless @value.is_a?(Array)
          part = [part] unless part.is_a?(Array)
          @value.concat(part)
        end
      end

      # Checks if this parameter contains the specified value.
      #
      # This is a case-insensitive match. It makes sense to call this for for
      # instance the TYPE parameter, to see if it contains a keyword such as
      # 'WORK' or 'FAX'.
      #
      # @param string value
      #
      # @return bool
      def has(value)
        value = value.downcase
        results = (@value.is_a?(Array) ? @value : [@value]).select do |entry|
          entry.downcase == value
        end
        results.any?
      end

      # Turns the object back into a serialized blob.
      #
      # @return string
      def serialize
        value = parts

        return "#{@name}=" if value.size == 0

        if @root.document_type == Document::VCARD21 && @no_name
          return value.join(';')
        end

        result = value.inject('') do |keep, item|
          keep += ',' unless keep == ''

          # If there's no special characters in the string, we'll use the simple
          # format.
          #
          # The list of special characters is defined as:
          #
          # Any character except CONTROL, DQUOTE, ";", ":", ","
          #
          # by the iCalendar spec:
          # https://tools.ietf.org/html/rfc5545#section-3.1
          #
          # And we add ^ to that because of:
          # https://tools.ietf.org/html/rfc6868
          #
          # But we've found that iCal (7.0, shipped with OSX 10.9)
          # severaly trips on + characters not being quoted, so we
          # added + as well.
          if !(item.to_s =~ /(?: [\n":;\^,\+] )/x)
            keep + item.to_s
          else
            # Enclosing in double-quotes, and using RFC6868 for encoding any
            # special characters
            keep += '"' + item.to_s.gsub(
              /[\^\n"]/,
              '^'  => '^^',
              "\n" => '^n',
              '"'  => '^\''
            )
            keep + '"'
          end
        end

        "#{@name}=#{result}"
      end

      # This method returns an array, with the representation as it should be
      # encoded in JSON. This is used to create jCard or jCal documents.
      #
      # @return array
      def json_serialize
        @value
      end

      # This method serializes the data into XML. This is used to create xCard or
      # xCal documents.
      #
      # @param Xml\Writer writer  XML writer.
      #
      # @return void
      def xml_serialize(writer)
        @value.split(',').each do |value|
          writer.write_element('text', value)
        end
      end

      # Called when this object is being cast to a string.
      #
      # @return string
      def to_s
        value.to_s
      end

      def each
        @value.each do |value|
          yield(value)
        end
      end

      def iterator
        return @iterator if @iterator

        @iterator = @value || []
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
