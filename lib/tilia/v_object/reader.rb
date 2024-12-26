module Tilia
  module VObject
    # iCalendar/vCard/jCal/jCard/xCal/xCard reader object.
    #
    # This object provides a few (static) convenience methods to quickly access
    # the parsers.
    class Reader
      # If this option is passed to the reader, it will be less strict about the
      # validity of the lines.
      OPTION_FORGIVING = 1

      # If this option is turned on, any lines we cannot parse will be ignored
      # by the reader.
      OPTION_IGNORE_INVALID_LINES = 2

      # Parses a vCard or iCalendar object, and returns the top component.
      #
      # The options argument is a bitfield. Pass any of the OPTIONS constant to
      # alter the parsers' behaviour.
      #
      # You can either supply a string, or a readable stream for input.
      #
      # @param [String, #read] data
      # @param [Integer] options
      # @param [String] charset
      # @return [Document]
      def self.read(data, options = 0, charset = 'UTF-8')
        parser = Parser::MimeDir.new
        parser.charset = charset
        result = parser.parse(data, options)

        result
      end

      # Parses a jCard or jCal object, and returns the top component.
      #
      # The options argument is a bitfield. Pass any of the OPTIONS constant to
      # alter the parsers' behaviour.
      #
      # You can either a string, a readable stream, or an array for it's input.
      # Specifying the array is useful if json_decode was already called on the
      # input.
      #
      # @param [String, |resource|array] data
      # @param [Integer] options
      #
      # @return [Document]
      def self.read_json(data, options = 0)
        parser = Parser::Json.new
        result = parser.parse(data, options)

        result
      end

      # Parses a xCard or xCal object, and returns the top component.
      #
      # The options argument is a bitfield. Pass any of the OPTIONS constant to
      # alter the parsers' behaviour.
      #
      # You can either supply a string, or a readable stream for input.
      #
      # @param [String|resource] data
      # @param [Integer] options
      #
      # @return [Document]
      def self.read_xml(data, options = 0)
        parser = Parser::Xml.new
        result = parser.parse(data, options)

        result
      end
    end
  end
end
