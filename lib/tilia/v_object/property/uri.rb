module Tilia
  module VObject
    class Property
      # URI property.
      #
      # This object encodes URI values. vCard 2.1 calls these URL.
      class Uri < Text
        # In case this is a multi-value property. This string will be used as a
        # delimiter.
        #
        # @var string|null
        attr_accessor :delimiter

        # Returns the type of value.
        #
        # This corresponds to the VALUE= parameter. Every property also has a
        # 'default' valueType.
        #
        # @return string
        def value_type
          'URI'
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
          # Normally we don't need to do any type of unescaping for these
          # properties, however.. we've noticed that Google Contacts
          # specifically escapes the colon (:) with a blackslash. While I have
          # no clue why they thought that was a good idea, I'm unescaping it
          # anyway.
          #
          # Good thing backslashes are not allowed in urls. Makes it easy to
          # assume that a backslash is always intended as an escape character.
          if name == 'URL'
            new_val = ''
            val.split(/  (?: (\\\\ (?: \\\\ | : ) ) ) /x).each do |match|
              case match
              when '\\:'
                new_val += ':'
              else
                new_val << match
              end
            end

            @value = new_val
          else
            @value = val.gsub('\\,', ',')
          end
        end

        # Returns a raw mime-dir representation of the value.
        #
        # @return string
        def raw_mime_dir_value
          if @value.is_a?(Array)
            value = @value[0]
          else
            value = @value
          end

          value.gsub(',', '\\,')
        end

        def initialize(*args)
          super(*args)
          @delimiter = nil
        end
      end
    end
  end
end
