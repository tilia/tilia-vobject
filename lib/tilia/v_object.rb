# Namespace for Tilia library
module Tilia
  # Load active support core extensions
  require 'active_support'
  require 'active_support/core_ext'

  # Mail encoding stuff
  require 'mail'

  # Char detecting functions
  require 'rchardet'

  # Our XML stuff
  require 'tilia/xml'

  # Namespace of tilia_vobject library
  module VObject
    require 'tilia/v_object/version'
    require 'tilia/v_object/element_list'
    require 'tilia/v_object/node'
    require 'tilia/v_object/parameter'
    require 'tilia/v_object/property'
    require 'tilia/v_object/date_time_parser'
    require 'tilia/v_object/uuid_util'
    require 'tilia/v_object/component'
    require 'tilia/v_object/document'
    require 'tilia/v_object/invalid_data_exception'
    require 'tilia/v_object/parse_exception'
    require 'tilia/v_object/eof_exception'
    require 'tilia/v_object/reader'
    require 'tilia/v_object/settings'
    require 'tilia/v_object/string_util'
    require 'tilia/v_object/time_zone_util'
    require 'tilia/v_object/writer'
    require 'tilia/v_object/i_tip'
    require 'tilia/v_object/parser'
    require 'tilia/v_object/recur'
    require 'tilia/v_object/splitter'
    require 'tilia/v_object/time_zone_data'
    require 'tilia/v_object/v_card_converter'
    require 'tilia/v_object/birthday_calendar_generator'
    require 'tilia/v_object/free_busy_data'
    require 'tilia/v_object/free_busy_generator'
    require 'tilia/v_object/cli'
  end
end
