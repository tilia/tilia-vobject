module Tilia
  module VObject
    class Property
      module ICalendar
        require 'tilia/v_object/property/i_calendar/cal_address'
        require 'tilia/v_object/property/i_calendar/date_time'
        require 'tilia/v_object/property/i_calendar/date'
        require 'tilia/v_object/property/i_calendar/duration'
        require 'tilia/v_object/property/i_calendar/period'
        require 'tilia/v_object/property/i_calendar/recur'
      end
    end
  end
end
