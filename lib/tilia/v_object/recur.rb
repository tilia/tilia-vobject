module Tilia
  module VObject
    # Namespace of the recurrence functionality
    module Recur
      require 'tilia/v_object/recur/max_instances_exceeded_exception'
      require 'tilia/v_object/recur/no_instances_exception'
      require 'tilia/v_object/recur/event_iterator'
      require 'tilia/v_object/recur/r_date_iterator'
      require 'tilia/v_object/recur/r_rule_iterator'
    end
  end
end
