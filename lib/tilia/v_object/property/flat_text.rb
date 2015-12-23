module Tilia
  module VObject
    class Property
      # FlatText property.
      #
      # This object represents certain TEXT values.
      #
      # Specifically, this property is used for text values where there is only 1
      # part. Semi-colons and colons will be de-escaped when deserializing, but if
      # any semi-colons or commas appear without a backslash, we will not assume
      # that they are delimiters.
      #
      # vCard 2.1 specifically has a whole bunch of properties where this may
      # happen, as it only defines a delimiter for a few properties.
      #
      # vCard 4.0 states something similar. An unescaped semi-colon _may_ be a
      # delimiter, depending on the property.
      class FlatText < Property::Text
        # Field separator.
        #
        # @var string
        attr_accessor :delimiter

        # Sets the value as a quoted-printable encoded string.
        #
        # Overriding this so we're not splitting on a ; delimiter.
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

          self.value = val
        end

        def initialize(*args)
          super(*args)
          @delimiter = ','
        end
      end
    end
  end
end
