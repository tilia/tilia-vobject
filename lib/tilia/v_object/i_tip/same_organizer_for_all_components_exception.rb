module Tilia
  module VObject
    module ITip
      # SameOrganizerForAllComponentsException.
      #
      # This exception is emitted when an event is encountered with more than one
      # component (e.g.: exceptions), but the organizer is not identical in every
      # component.
      class SameOrganizerForAllComponentsException < ITipException
      end
    end
  end
end
