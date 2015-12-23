module Tilia
  module VObject
    class Property
      module ICalendar
        # DateTime property.
        #
        # This object represents DATE values, as defined here:
        #
        # http://tools.ietf.org/html/rfc5545#section-3.3.5
        class Date < DateTime
        end
      end
    end
  end
end
