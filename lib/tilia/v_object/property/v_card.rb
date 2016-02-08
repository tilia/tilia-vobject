module Tilia
  module VObject
    class Property
      # Namespace of the VCard Properties
      module VCard
        require 'tilia/v_object/property/v_card/date_and_or_time'
        require 'tilia/v_object/property/v_card/date'
        require 'tilia/v_object/property/v_card/date_time'
        require 'tilia/v_object/property/v_card/language_tag'
        require 'tilia/v_object/property/v_card/time_stamp'
      end
    end
  end
end
