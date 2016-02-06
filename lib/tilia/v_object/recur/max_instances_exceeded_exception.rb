module Tilia
  module VObject
    module Recur
      # This exception will get thrown when a recurrence rule generated more than
      # the maximum number of instances.
      class MaxInstancesExceededException < StandardError
      end
    end
  end
end
