module Tilia
  module VObject
    class Property
      # Text property.
      #
      # This object represents TEXT values.
      class Text < Property
        # In case this is a multi-value property. This string will be used as a
        # delimiter.
        #
        # @var string
        attr_accessor :delimiter

        # List of properties that are considered 'structured'.
        #
        # @var array
        # RUBY: attr_accessor :structured_values

        # Some text components have a minimum number of components.
        #
        # N must for instance be represented as 5 components, separated by ;, even
        # if the last few components are unused.
        #
        # @var array
        # RUBY: attr_accessor :minimum_property_values

        # Creates the property.
        #
        # You can specify the parameters either in key=>value syntax, in which case
        # parameters will automatically be created, or you can just pass a list of
        # Parameter objects.
        #
        # @param Component root The root document
        # @param string name
        # @param string|array|null value
        # @param array parameters List of parameters
        # @param string group The vcard property group
        #
        # @return void
        def initialize(root, name, value = nil, parameters = [], group = nil)
          super(root, name, value, parameters, group)

          @delimiter = ','
          @structured_values = [
            # vCard
            'N',
            'ADR',
            'ORG',
            'GENDER',
            'CLIENTPIDMAP',

            # iCalendar
            'REQUEST-STATUS'
          ]
          @minimum_property_values = {
            'N'   => 5,
            'ADR' => 7
          }

          # There's two types of multi-valued text properties:
          # 1. multivalue properties.
          # 2. structured value properties
          #
          # The former is always separated by a comma, the latter by semi-colon.
          @delimiter = ';' if @structured_values.include?(name)
        end

        # Sets a raw value coming from a mimedir (iCalendar/vCard) file.
        #
        # This has been 'unfolded', so only 1 line will be passed. Unescaping is
        # not yet done, but parameters are not included.
        #
        # @param string val
        #
        # @return void
        def raw_mime_dir_value=(val)
          self.value = Parser::MimeDir.unescape_value(val, @delimiter)
        end

        # Sets the value as a quoted-printable encoded string.
        #
        # @param string val
        #
        # @return void
        def quoted_printable_value=(val)
          val = Mail::Encodings::QuotedPrintable.decode(val)
          val = val.gsub(/\n/, "\r\n").gsub(/\r\r/, "\r")

          # force the correct encoding
          begin
            val.force_encoding(Encoding.find(@parameters['CHARSET'].to_s))
          rescue
            val.force_encoding(Encoding::UTF_8)
          end

          # Quoted printable only appears in vCard 2.1, and the only character
          # that may be escaped there is ;. So we are simply splitting on just
          # that.
          #
          # We also don't have to unescape \\, so all we need to look for is a
          # that's not preceeded with a \.
          matches = val.split(/ (?<!\\\\) ; /x)
          self.value = matches
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return string
        def raw_mime_dir_value
          val = parts

          if @minimum_property_values.key?(@name)
            val << '' while val.size < @minimum_property_values[@name]
          end

          val = val.map do |item|
            item = [item] unless item.is_a?(Array)

            item = item.map do |sub_item|
              sub_item.to_s.gsub(
                /[\\;,\n\r]/,
                '\\' => '\\\\',
                ';'  => '\;',
                ','  => '\,',
                "\n" => '\n',
                "\r" => ''
              )
            end
            item.join(',')
          end

          val.join(@delimiter)
        end

        # Returns the value, in the format it should be encoded for json.
        #
        # This method must always return an array.
        #
        # @return array
        def json_value
          # Structured text values should always be returned as a single
          # array-item. Multi-value text should be returned as multiple items in
          # the top-array.
          return [parts] if @structured_values.include?(@name)

          parts
        end

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'TEXT'
        end

        # Turns the object back into a serialized blob.
        #
        # @return string
        def serialize
          # We need to kick in a special type of encoding, if it's a 2.1 vcard.
          return super unless @root.document_type == Document::VCARD21

          val = parts

          if @minimum_property_values.key?(@name)
            val << '' while val.size < @minimum_property_values[@name]
          end

          # Imploding multiple parts into a single value, and splitting the
          # values with ;.
          if val.size > 1
            val = val.map do |v|
              v.gsub(';', '\\;')
            end
            val = val.join(';')
          else
            val = val[0]
          end

          str = @name
          str = "#{@group}.#{@name}" if @group

          @parameters.each do |_key, param|
            next if param.value == 'QUOTED-PRINTABLE'

            str += ';' + param.serialize
          end

          # If the resulting value contains a \n, we must encode it as
          # quoted-printable.
          if val.index("\n")
            str += ';ENCODING=QUOTED-PRINTABLE:'
            last_line = str
            out = ''

            # The PHP built-in quoted-printable-encode does not correctly
            # encode newlines for us. Specifically, the \r\n sequence must in
            # vcards be encoded as =0D=OA and we must insert soft-newlines
            # every 75 bytes.
            val.bytes.each do |ord|
              # These characters are encoded as themselves.
              if ord >= 32 && ord <= 126
                last_line += ord.chr
              else
                last_line += format('=%02X', ord)
              end

              next unless last_line.length >= 75
              out += last_line + "=\r\n "
              last_line = ''
            end

            out += last_line + "\r\n" unless last_line.blank?
            return out
          else
            str += ':' + val
            out = ''

            while str.length > 0
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

            return out
          end
        end

        protected

        # This method serializes only the value of a property. This is used to
        # create xCard or xCal documents.
        #
        # @param Xml\Writer writer  XML writer.
        #
        # @return void
        def xml_serialize_value(writer)
          values = parts

          map = lambda do |items|
            items.each_with_index do |item, i|
              writer.write_element(
                item,
                values[i].blank? ? nil : values[i]
              )
            end
          end

          case @name
          # Special-casing the REQUEST-STATUS property.
          #
          # See:
          # http://tools.ietf.org/html/rfc6321#section-3.4.1.3
          when 'REQUEST-STATUS'
            writer.write_element('code', values[0])
            writer.write_element('description', values[1])

            writer.write_element('data', values[2]) if values[2]
          when 'N'
            map.call(
              [
                'surname',
                'given',
                'additional',
                'prefix',
                'suffix'
              ]
            )
          when 'GENDER'
            map.call(
              [
                'sex',
                'text'
              ]
            )
          when 'ADR'
            map.call(
              [
                'pobox',
                'ext',
                'street',
                'locality',
                'region',
                'code',
                'country'
              ]
            )
          when 'CLIENTPIDMAP'
            map.call(
              [
                'sourceid',
                'uri'
              ]
            )
          else
            super(writer)
          end
        end

        public

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
          warnings = super(options)

          if @minimum_property_values.key?(@name)
            minimum = @minimum_property_values[@name]
            parts = self.parts
            if parts.size < minimum
              warnings << {
                'level'   => 1,
                'message' => "This property must have at least #{minimum} components. It only has #{parts.size}",
                'node'    => self
              }

              if options & self.class::REPAIR > 0
                parts << '' while parts.size < minimum
                self.parts = parts
              end
            end
          end

          warnings
        end
      end
    end
  end
end
