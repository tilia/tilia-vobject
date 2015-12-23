module Tilia
  module VObject
    module Splitter
      # VObject splitter.
      #
      # The splitter is responsible for reading a large vCard or iCalendar object,
      # and splitting it into multiple objects.
      #
      # This is for example for Card and CalDAV, which require every event and vcard
      # to exist in their own objects, instead of one large one.
      module SplitterInterface
        # Constructor.
        #
        # The splitter should receive an readable file stream as it's input.
        #
        # @param resource input
        def initialize(_input)
        end

        # Every time self.next is called, a new object will be parsed, until we
        # hit the end of the stream.
        #
        # When the end is reached, null will be returned.
        #
        # @return Sabre\VObject\Component|null
        def next
        end
      end
    end
  end
end
