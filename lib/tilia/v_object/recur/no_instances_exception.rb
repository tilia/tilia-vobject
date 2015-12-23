module Tilia
  module VObject
    module Recur
      # This exception gets thrown when a recurrence iterator produces 0 instances.
      #
      # This may happen when every occurence in a rrule is also in EXDATE.
      class NoInstancesException < Exception
      end
    end
  end
end
