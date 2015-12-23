module Tilia
  module VObject
    # Exception thrown by parser when the end of the stream has been reached,
    # before this was expected.
    class EofException < ParseException
    end
  end
end
