module Tilia
  module VObject
    # VObject ElementList.
    #
    # This class represents a list of elements. Lists are the result of queries,
    # such as doing vcalendar.vevent where there's multiple VEVENT objects.
    class ElementList < Array
      def initialize(*args)
        super(*args)
        freeze
      end

      def delete(_offset)
        fail 'RuntimeError: can\'t modify frozen Array'
      end
    end
  end
end
