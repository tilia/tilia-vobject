module Tilia
  module VObject
    # This class provides a list of global defaults for vobject.
    #
    # Some of these started to appear in various classes, so it made a bit more
    # sense to centralize them, so it's easier for user to find and change these.
    #
    # The global nature of them does mean that changing the settings for one
    # instance has a global influence.
    class Settings
      # The minimum date we accept for various calculations with dates, such as
      # recurrences.
      #
      # The choice of 1900 is pretty arbitrary, but it covers most common
      # use-cases. In particular, it covers birthdates for virtually everyone
      # alive on earth, which is less than 5 people at the time of writing.
      @min_date = '1900-01-01'

      # The maximum date we accept for various calculations with dates, such as
      # recurrences.
      #
      # The choice of 2100 is pretty arbitrary, but should cover most
      # appointments made for many years to come.
      @max_date = '2100-01-01'

      class << self
        attr_accessor :min_date
        attr_accessor :max_date
      end
    end
  end
end
