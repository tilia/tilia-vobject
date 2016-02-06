require 'stringio'
module Tilia
  module VObject
    module Parser
      # MimeDir parser.
      #
      # This class parses iCalendar 2.0 and vCard 2.1, 3.0 and 4.0 files. This
      # parser will return one of the following two objects from the parse method:
      #
      # Sabre\VObject\Component\VCalendar
      # Sabre\VObject\Component\VCard
      class MimeDir < Parser
        # The list of character sets we support when decoding.
        #
        # This would be a const expression but for now we need to support PHP 5.5
        @supported_charsets = [
            'UTF-8',
            'ISO-8859-1',
            'Windows-1252',
        ]

        class << self
          attr_reader :supported_charsets
        end

        # Parses an iCalendar or vCard file.
        #
        # Pass a stream or a string. If null is parsed, the existing buffer is
        # used.
        #
        # @param string|resource|null input
        # @param int options
        #
        # @return Sabre\VObject\Document
        def parse(input = nil, options = 0)
          @root = nil

          self.input = input unless input.nil?
          @options = options if options != 0

          parse_document

          @root
        end

        # By default all input will be assumed to be UTF-8.
        #
        # However, both iCalendar and vCard might be encoded using different
        # character sets. The character set is usually set in the mime-type.
        #
        # If this is the case, use setEncoding to specify that a different
        # encoding will be used. If this is set, the parser will automatically
        # convert all incoming data to UTF-8.
        #
        # @param string charset
        def charset=(charset)
          fail ArgumentError, "Unsupported encoding. (Supported encodings: #{MimeDir.supported_charsets.join(', ')})" unless MimeDir.supported_charsets.include?(charset)

          @charset = charset
        end

         # Sets the input buffer. Must be a string or stream.
        #
        # @param resource|string input
        #
        # @return void
        def input=(input)
          # Resetting the parser
          @line_index = 0
          @start_line = 0

          if input.is_a?(String)
            # Convering to a stream.
            stream = StringIO.new
            stream.write(input)
            stream.rewind
            @input = stream
          elsif input.respond_to?(:read)
            @input = input
          else
            fail ArgumentError, 'This parser can only read from strings or streams.'
          end
        end

        protected

        # Parses an entire document.
        #
        # @return void
        def parse_document
          line = read_line

          # BOM is ZERO WIDTH NO-BREAK SPACE (U+FEFF).
          # It's 0xEF 0xBB 0xBF in UTF-8 hex.
          line.sub!("\xEF\xBB\xBF", '')

          case line.upcase
          when 'BEGIN:VCALENDAR'
            klass = Component::VCalendar.component_map['VCALENDAR']
          when 'BEGIN:VCARD'
            klass = Component::VCard.component_map['VCARD']
          else
            fail ParseException, 'This parser only supports VCARD and VCALENDAR files'
          end

          @root = klass.new({}, false)

          loop do
            # Reading until we hit END:
            line = read_line
            break if line[0...4].upcase == 'END:'
            result = parse_line(line)
            @root.add(result) if result
          end

          name = line[4..-1].upcase
          if name != @root.name
            fail Tilia::VObject::ParseException, "Invalid MimeDir file. expected: \"END:#{@root.name}\" got: \"END:#{name}\""
          end
        end

        # Parses a line, and if it hits a component, it will also attempt to parse
        # the entire component.
        #
        # @param string line Unfolded line
        #
        # @return Node
        def parse_line(line)
          # Start of a new component
          if line[0...6].upcase == 'BEGIN:'
            component = @root.create_component(line[6..-1], [], false)

            loop do
              # Reading until we hit END:
              line = read_line
              break if line[0...4].upcase == 'END:'

              result = parse_line(line)
              component.add(result) if result
            end

            name = line[4..-1].upcase
            if name != component.name
              fail Tilia::VObject::ParseException, "Invalid MimeDir file. expected: \"END:#{component.name}\" got: \"END:#{name}\""
            end

            component
          else
            # Property reader
            property = read_property(line)
            unless property
              # Ignored line
              return false
            end

            property
          end
        end

        # We need to look ahead 1 line every time to see if we need to 'unfold'
        # the next line.
        #
        # If that was not the case, we store it here.
        #
        # @var null|string
        # RUBY: attr_accessor :protected line_buffer

        # The real current line number.
        # RUBY: attr_accessor :protected line_index

        # In the case of unfolded lines, this property holds the line number for
        # the start of the line.
        #
        # @var int
        # RUBY: attr_accessor :start_line

        # Contains a 'raw' representation of the current line.
        #
        # @var string
        # RUBY: attr_accessor :raw_line

        # Reads a single line from the buffer.
        #
        # This method strips any newlines and also takes care of unfolding.
        #
        # @throws \Sabre\VObject\EofException
        #
        # @return string
        def read_line
          if !@line_buffer.nil?
            raw_line = @line_buffer
            @line_buffer = nil
          else
            loop do
              if @input.eof?
                fail Tilia::VObject::EofException, 'End of document reached prematurely'
              end

              raw_line = @input.readline

              unless raw_line
                fail Tilia::VObject::ParseException, 'Error reading from input stream'
              end

              raw_line.chomp!
              break unless raw_line == '' # Skipping empty lines
            end

            @line_index += 1
          end
          line = raw_line

          @start_line = @line_index

          # Looking ahead for folded lines.
          loop do
            begin
              next_line = @input.readline.chomp
            rescue EOFError
              next_line = ''
            end

            @line_index += 1
            break if next_line == ''
            if next_line[0] == "\t" || next_line[0] == ' '
              line += next_line[1..-1]
              raw_line += "\n " + next_line[1..-1]
            else
              @line_buffer = next_line
              break
            end
          end

          @raw_line = raw_line
          line
        end

        # Reads a property or component from a line.
        #
        # @return void
        def read_property(line)
          if @options & OPTION_FORGIVING > 0
            prop_name_token = 'A-Z0-9\\-\\._\\/'
          else
            prop_name_token = 'A-Z0-9\\-\\.'
          end

          param_name_token = 'A-Z0-9\\-'
          safe_char = '^";:,'
          q_safe_char = '^"'

          regex = /
              ^(?<name> [#{prop_name_token}]+ ) (?=[;:])        # property name
              |
              (?<=:)(?<propValue> .+)$                      # property value
              |
              ;(?<paramName> [#{param_name_token}]+) (?=[=;:])  # parameter name
              |
              (=|,)(?<paramValue>                           # parameter value
                  (?: [#{safe_char}]*) |
                  \"(?: [#{q_safe_char}]+)\"
              ) (?=[;:,])
              /xi

          # RUBY: We have to convert the string to UTF-8 for Regexp
          encoding = StringUtil.guess_encoding(line)
          line = line.encode(encoding, encoding)
          matches = line.scan(regex)

          property = {
            'name'       => nil,
            'parameters' => {},
            'value'      => nil
          }

          last_param = nil

          # Looping through all the tokens.
          #
          # Note that we are looping through them in reverse order, because if a
          # sub-pattern matched, the subsequent named patterns will not show up
          # in the result.
          matches.each do |match|
            match = Hash[['name', 'propValue', 'paramName', 'paramValue'].zip(match)]
            match.delete_if { |_k, v| v.nil? }

            if match.key?('paramValue')
              if match['paramValue'] && match['paramValue'][0] == '"'
                value = match['paramValue'][1..-2]
              else
                value = match['paramValue']
              end

              value = unescape_param(value)

              if last_param.nil?
                fail Tilia::VObject::ParseException, "Invalid Mimedir file. Line starting at #{@start_line} did not follow iCalendar/vCard conventions"
              end

              if property['parameters'][last_param].nil?
                property['parameters'][last_param] = value
              elsif property['parameters'][last_param].is_a?(Array)
                property['parameters'][last_param] << value
              else
                property['parameters'][last_param] = [
                  property['parameters'][last_param],
                  value
                ]
              end
              next
            end

            if match.key?('paramName')
              last_param = match['paramName'].upcase
              unless property['parameters'].key?(last_param)
                property['parameters'][last_param] = nil
              end
              next
            end
            if match.key?('propValue')
              property['value'] = match['propValue']
              next
            end
            if match.key?('name') && !match['name'].blank?
              property['name'] = match['name'].upcase
              next
            end

            # @codeCoverageIgnoreStart
            fail 'This code should not be reachable'
            # @codeCoverageIgnoreEnd
          end

          property['value'] = '' if property['value'].nil?
          if property['name'].blank?
            if @options & OPTION_IGNORE_INVALID_LINES > 0
              return false
            end
            fail Tilia::VObject::ParseException, "Invalid Mimedir file. Line starting at #{@start_line} did not follow iCalendar/vCard conventions"
          end

          # vCard 2.1 states that parameters may appear without a name, and only
          # a value. We can deduce the value based on it's name.
          #
          # Our parser will get those as parameters without a value instead, so
          # we're filtering these parameters out first.
          named_parameters = {}
          nameless_parameters = []

          property['parameters'].each do |name, value|
            if !value.nil?
              named_parameters[name] = value
            else
              nameless_parameters << name
            end
          end

          prop_obj = @root.create_property(property['name'], nil, named_parameters)

          nameless_parameters.each do |nameless_parameter|
            prop_obj.add(nil, nameless_parameter)
          end

          if prop_obj.key?('ENCODING') && prop_obj['ENCODING'].to_s.upcase == 'QUOTED-PRINTABLE'
            prop_obj.quoted_printable_value = extract_quoted_printable_value
          else
            charset = @charset
            if @root.document_type == Document::VCARD21 && prop_obj.key?('CHARSET')
              # vCard 2.1 allows the character set to be specified per property.
              charset = prop_obj['CHARSET'].to_s
            end

            case charset
            when 'UTF-8'
              # NOOP
            when 'ISO-8859-1',
                'Windows-1252'
              property['value'] = property['value'].to_s.encode('UTF-8', charset)
            else
              fail ParseException, "Unsupported CHARSET: #{charset.to_s}"
            end
            prop_obj.raw_mime_dir_value = property['value']
          end

          prop_obj
        end

        public

        # Unescapes a property value.
        #
        # vCard 2.1 says:
        #   * Semi-colons must be escaped in some property values, specifically
        #     ADR, ORG and N.
        #   * Semi-colons must be escaped in parameter values, because semi-colons
        #     are also use to separate values.
        #   * No mention of escaping backslashes with another backslash.
        #   * newlines are not escaped either, instead QUOTED-PRINTABLE is used to
        #     span values over more than 1 line.
        #
        # vCard 3.0 says:
        #   * (rfc2425) Backslashes, newlines (\n or \N) and comma's must be
        #     escaped, all time time.
        #   * Comma's are used for delimeters in multiple values
        #   * (rfc2426) Adds to to this that the semi-colon MUST also be escaped,
        #     as in some properties semi-colon is used for separators.
        #   * Properties using semi-colons: N, ADR, GEO, ORG
        #   * Both ADR and N's individual parts may be broken up further with a
        #     comma.
        #   * Properties using commas: NICKNAME, CATEGORIES
        #
        # vCard 4.0 (rfc6350) says:
        #   * Commas must be escaped.
        #   * Semi-colons may be escaped, an unescaped semi-colon _may_ be a
        #     delimiter, depending on the property.
        #   * Backslashes must be escaped
        #   * Newlines must be escaped as either \N or \n.
        #   * Some compound properties may contain multiple parts themselves, so a
        #     comma within a semi-colon delimited property may also be unescaped
        #     to denote multiple parts _within_ the compound property.
        #   * Text-properties using semi-colons: N, ADR, ORG, CLIENTPIDMAP.
        #   * Text-properties using commas: NICKNAME, RELATED, CATEGORIES, PID.
        #
        # Even though the spec says that commas must always be escaped, the
        # example for GEO in Section 6.5.2 seems to violate this.
        #
        # iCalendar 2.0 (rfc5545) says:
        #   * Commas or semi-colons may be used as delimiters, depending on the
        #     property.
        #   * Commas, semi-colons, backslashes, newline (\N or \n) are always
        #     escaped, unless they are delimiters.
        #   * Colons shall not be escaped.
        #   * Commas can be considered the 'default delimiter' and is described as
        #     the delimiter in cases where the order of the multiple values is
        #     insignificant.
        #   * Semi-colons are described as the delimiter for 'structured values'.
        #     They are specifically used in Semi-colons are used as a delimiter in
        #     REQUEST-STATUS, RRULE, GEO and EXRULE. EXRULE is deprecated however.
        #
        # Now for the parameters
        #
        # If delimiter is not set (null) this method will just return a string.
        # If it's a comma or a semi-colon the string will be split on those
        # characters, and always return an array.
        #
        # @param string input
        # @param string delimiter
        #
        # @return string|string[]
        def self.unescape_value(input, delimiter = ';')
          regex = '(?: (\\\\ (?: \\\\ | N | n | ; | , ) )'
          regex += ' | (' + delimiter + ')' unless delimiter.blank?
          regex += ')'

          regexp = Regexp.compile(regex, Regexp::EXTENDED)
          matches = input.split(regexp)

          result_array = []
          result = ''

          matches.each do |match|
            case match
            when '\\\\'
              result += '\\'
            when '\\N', '\\n'
              result += "\n"
            when '\\;'
              result += ';'
            when '\\,'
              result += ','
            when delimiter
              result_array << result
              result = ''
            else
              result += match
            end
          end

          result_array << result
          delimiter ? result_array : result
        end

        private

        # Unescapes a parameter value.
        #
        # vCard 2.1:
        #   * Does not mention a mechanism for this. In addition, double quotes
        #     are never used to wrap values.
        #   * This means that parameters can simply not contain colons or
        #     semi-colons.
        #
        # vCard 3.0 (rfc2425, rfc2426):
        #   * Parameters _may_ be surrounded by double quotes.
        #   * If this is not the case, semi-colon, colon and comma may simply not
        #     occur (the comma used for multiple parameter values though).
        #   * If it is surrounded by double-quotes, it may simply not contain
        #     double-quotes.
        #   * This means that a parameter can in no case encode double-quotes, or
        #     newlines.
        #
        # vCard 4.0 (rfc6350)
        #   * Behavior seems to be identical to vCard 3.0
        #
        # iCalendar 2.0 (rfc5545)
        #   * Behavior seems to be identical to vCard 3.0
        #
        # Parameter escaping mechanism (rfc6868) :
        #   * This rfc describes a new way to escape parameter values.
        #   * New-line is encoded as ^n
        #   * ^ is encoded as ^^.
        #   * " is encoded as ^'
        #
        # @param string input
        #
        # @return void
        def unescape_param(input)
          input.gsub(/(\^(\^|n|\'))/) do |match|
            case match
            when '^n'
              "\n"
            when '^^'
              '^'
            when '^\''
              '"'
            end
          end
        end

        # Gets the full quoted printable value.
        #
        # We need a special method for this, because newlines have both a meaning
        # in vCards, and in QuotedPrintable.
        #
        # This method does not do any decoding.
        #
        # @return string
        def extract_quoted_printable_value
          # We need to parse the raw line again to get the start of the value.
          #
          # We are basically looking for the first colon (:), but we need to
          # skip over the parameters first, as they may contain one.
          regex = /^
              (?: [^:])+ # Anything but a colon
              (?: "[^"]")* # A parameter in double quotes
              : # start of the value we really care about
              (.*)$
          /xm

          matches = regex.match(@raw_line)

          value = matches[1]
          # Removing the first whitespace character from every line. Kind of
          # like unfolding, but we keep the newline.
          value = value.gsub("\n ", "\n")

          # Microsoft products don't always correctly fold lines, they may be
          # missing a whitespace. So if 'forgiving' is turned on, we will take
          # those as well.
          if @options & OPTION_FORGIVING > 0
            while value[-1] == '='
              # Reading the line
              read_line
              # Grabbing the raw form
              value += "\n" + @raw_line
            end
          end

          value
        end

        def initialize(*args)
          super(*args)
          @start_line = 0
          @line_index = 0
          @charset = 'UTF-8'
        end
      end
    end
  end
end
