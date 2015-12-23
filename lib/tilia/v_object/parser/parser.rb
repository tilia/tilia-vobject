module Tilia
  module VObject
    module Parser
      # Abstract parser.
      #
      # This class serves as a base-class for the different parsers.
      class Parser
        # Turning on this option makes the parser more forgiving.
        #
        # In the case of the MimeDir parser, this means that the parser will
        # accept slashes and underscores in property names, and it will also
        # attempt to fix Microsoft vCard 2.1's broken line folding.
        OPTION_FORGIVING ||= 1

        # If this option is turned on, any lines we cannot parse will be ignored
        # by the reader.
        OPTION_IGNORE_INVALID_LINES ||= 2

        # Bitmask of parser options.
        #
        # @var int
        # RUBY: attr_accessor :options

        # Creates the parser.
        #
        # Optionally, it's possible to parse the input stream here.
        #
        # @param mixed input
        # @param int options Any parser options (OPTION constants).
        #
        # @return void
        def initialize(input = nil, options = 0)
          self.input = input unless input.nil?
          @options = options
        end

        # This method starts the parsing process.
        #
        # If the input was not supplied during construction, it's possible to pass
        # it here instead.
        #
        # If either input or options are not supplied, the defaults will be used.
        #
        # @param mixed input
        # @param int options
        #
        # @return array
        def parse(_input = nil, _options = 0)
        end

        # Sets the input data.
        #
        # @param mixed input
        #
        # @return void
        def input=(_input)
        end
      end
    end
  end
end
