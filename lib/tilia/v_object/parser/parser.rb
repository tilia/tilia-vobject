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
        OPTION_FORGIVING = 1

        # If this option is turned on, any lines we cannot parse will be ignored
        # by the reader.
        OPTION_IGNORE_INVALID_LINES = 2

        # Creates the parser.
        #
        # Optionally, it's possible to parse the input stream here.
        #
        # @param input
        # @param [Fixnum] options Any parser options (OPTION constants).
        #
        # @return [void]
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
        # @param input
        # @param [Fixnum] options
        #
        # @return [Document]
        def parse(input = nil, options = 0)
        end

        # Sets the input data.
        #
        # @param input
        #
        # @return [void]
        def input=(_input)
        end
      end
    end
  end
end
