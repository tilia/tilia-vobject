module Tilia
  module VObject
    # This exception is thrown whenever an invalid value is found anywhere in a
    # iCalendar or vCard object.
    class InvalidDataException < StandardError
    end
  end
end
