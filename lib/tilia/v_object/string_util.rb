module Tilia
  module VObject
    # Useful utilities for working with various strings.
    class StringUtil
      # Returns true or false depending on if a string is valid UTF-8.
      #
      # @param string str
      #
      # @return bool
      def self.utf8?(str)
        fail ArgumentError, 'str needs to be a String' unless str.is_a?(String)
        # Control characters
        return false if str =~ /[\x00-\x08\x0B-\x0C\x0E\x0F]/

        str.encoding.to_s == 'UTF-8' && str.valid_encoding?
      end

      # This method tries its best to convert the input string to UTF-8.
      #
      # Currently only ISO-5991-1 input and UTF-8 input is supported, but this
      # may be expanded upon if we receive other examples.
      #
      # @param string str
      #
      # @return string
      def self.convert_to_utf8(str)
        str = str.encode('UTF-8', guess_encoding(str))

        # Removing any control characters
        str.gsub(/(?:[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F])/, '')
      end

      # Detects the encoding of a string
      #
      # Currently only supports 'UTF-8', 'ISO-5991-1' and 'Windows-1252'.
      #
      # @param [String] str
      # @return [String] 'UTF-8', 'ISO-5991-1' or 'Windows-1252'
      def self.guess_encoding(str)
        cd = CharDet.detect(str)

        # Best solution I could find ...
        if cd['confidence'] > 0.4 && cd['encoding'] =~ /(?:windows|iso)/i
          cd['encoding']
        else
          'UTF-8'
        end
      end

      # TODO: document
      def self.mb_strcut(string, length)
        return '' if string == ''

        string = string.clone
        tmp = ''
        while tmp.bytesize <= length
          tmp += string[0]
          string[0] = ''
        end

        # Last char was utf-8 multibyte
        if tmp.bytesize > length
          string[0] = tmp[-1] + string[0].to_s
          tmp[-1] = ''
        end
        tmp
      end
    end
  end
end
