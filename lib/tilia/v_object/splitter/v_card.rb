module Tilia
  module VObject
    module Splitter
      # Splitter.
      #
      # This class is responsible for splitting up VCard objects.
      #
      # It is assumed that the input stream contains 1 or more VCARD objects. This
      # class checks for BEGIN:VCARD and END:VCARD and parses each encountered
      # component individually.
      class VCard
        include SplitterInterface
        # File handle.
        #
        # @return [resource]
        # RUBY: attr_accessor :input

        # Persistent parser.
        #
        # @return [MimeDir]
        # RUBY: attr_accessor :parser

        # Constructor.
        #
        # The splitter should receive an readable file stream as it's input.
        #
        # @param [resource] input
        # @param [Integer] options Parser options, see the OPTIONS constants.
        def initialize(input, options = 0)
          @input = input
          @parser = Parser::MimeDir.new(input, options)
        end

        # Every time self.next is called, a new object will be parsed, until we
        # hit the end of the stream.
        #
        # When the end is reached, null will be returned.
        #
        # @return [Sabre\VObject\Component, nil]
        def next
          begin
            object = @parser.parse

            unless object.is_a?(Component::VCard)
              fail ParseException, 'The supplied input contained non-VCARD data.'
            end
          rescue EofException
            return nil
          end

          object
        end
      end
    end
  end
end
