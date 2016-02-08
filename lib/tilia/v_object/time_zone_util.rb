module Tilia
  module VObject
    # Time zone name translation.
    #
    # This file translates well-known time zone names into "Olson database" time zone names.
    class TimeZoneUtil
      @map = nil

      # List of microsoft exchange timezone ids.
      #
      # Source: http://msdn.microsoft.com/en-us/library/aa563018(loband).aspx
      @microsoft_exchange_map = {
        0  => 'UTC',
        31 => 'Africa/Casablanca',

        # Insanely, id #2 is used for both Europe/Lisbon, and Europe/Sarajevo.
        # I'm not even kidding.. We handle this special case in the
        # getTimeZone method.
        2  => 'Europe/Lisbon',
        1  => 'Europe/London',
        4  => 'Europe/Berlin',
        6  => 'Europe/Prague',
        3  => 'Europe/Paris',
        69 => 'Africa/Luanda', # This was a best guess
        7  => 'Europe/Athens',
        5  => 'Europe/Bucharest',
        49 => 'Africa/Cairo',
        50 => 'Africa/Harare',
        59 => 'Europe/Helsinki',
        27 => 'Asia/Jerusalem',
        26 => 'Asia/Baghdad',
        74 => 'Asia/Kuwait',
        51 => 'Europe/Moscow',
        56 => 'Africa/Nairobi',
        25 => 'Asia/Tehran',
        24 => 'Asia/Muscat', # Best guess
        54 => 'Asia/Baku',
        48 => 'Asia/Kabul',
        58 => 'Asia/Yekaterinburg',
        47 => 'Asia/Karachi',
        23 => 'Asia/Calcutta',
        62 => 'Asia/Kathmandu',
        46 => 'Asia/Almaty',
        71 => 'Asia/Dhaka',
        66 => 'Asia/Colombo',
        61 => 'Asia/Rangoon',
        22 => 'Asia/Bangkok',
        64 => 'Asia/Krasnoyarsk',
        45 => 'Asia/Shanghai',
        63 => 'Asia/Irkutsk',
        21 => 'Asia/Singapore',
        73 => 'Australia/Perth',
        75 => 'Asia/Taipei',
        20 => 'Asia/Tokyo',
        72 => 'Asia/Seoul',
        70 => 'Asia/Yakutsk',
        19 => 'Australia/Adelaide',
        44 => 'Australia/Darwin',
        18 => 'Australia/Brisbane',
        76 => 'Australia/Sydney',
        43 => 'Pacific/Guam',
        42 => 'Australia/Hobart',
        68 => 'Asia/Vladivostok',
        41 => 'Asia/Magadan',
        17 => 'Pacific/Auckland',
        40 => 'Pacific/Fiji',
        67 => 'Pacific/Tongatapu',
        29 => 'Atlantic/Azores',
        53 => 'Atlantic/Cape_Verde',
        30 => 'America/Noronha',
        8  => 'America/Sao_Paulo', # Best guess
        32 => 'America/Argentina/Buenos_Aires',
        60 => 'America/Godthab',
        28 => 'America/St_Johns',
        9  => 'America/Halifax',
        33 => 'America/Caracas',
        65 => 'America/Santiago',
        35 => 'America/Bogota',
        10 => 'America/New_York',
        34 => 'America/Indiana/Indianapolis',
        55 => 'America/Guatemala',
        11 => 'America/Chicago',
        37 => 'America/Mexico_City',
        36 => 'America/Edmonton',
        38 => 'America/Phoenix',
        12 => 'America/Denver', # Best guess
        13 => 'America/Los_Angeles', # Best guess
        14 => 'America/Anchorage',
        15 => 'Pacific/Honolulu',
        16 => 'Pacific/Midway',
        39 => 'Pacific/Kwajalein'
      }

      # This method will try to find out the correct timezone for an iCalendar
      # date-time value.
      #
      # You must pass the contents of the TZID parameter, as well as the full
      # calendar.
      #
      # If the lookup fails, this method will return the default PHP timezone
      # (as configured using date_default_timezone_set, or the date.timezone ini
      # setting).
      #
      # Alternatively, if fail_if_uncertain is set to true, it will throw an
      # exception if we cannot accurately determine the timezone.
      #
      # @param [String] tzid
      # @param [Component] vcalendar
      #
      # @return [ActiveSupport::TimeZone]
      def self.time_zone(tzid, vcalendar = nil, fail_if_uncertain = false)
        # First we will just see if the tzid is a support timezone identifier.
        #
        # The only exception is if the timezone starts with (. This is to
        # handle cases where certain microsoft products generate timezone
        # identifiers that for instance look like:
        #
        # (GMT+01.00) Sarajevo/Warsaw/Zagreb
        #
        # Since PHP 5.5.10, the first bit will be used as the timezone and
        # this method will return just GMT+01:00. This is wrong, because it
        # doesn't take DST into account.

        unless tzid[0] == '('

          # PHP has a bug that logs PHP warnings even it shouldn't:
          # https://bugs.php.net/bug.php?id=67881
          #
          # That's why we're checking if we'll be able to successfull instantiate
          # \Date_time_zone before doing so. Otherwise we could simply instantiate
          # and catch the exception.
          return ActiveSupport::TimeZone.new(tzid) if ActiveSupport::TimeZone.new(tzid)
        end

        load_tz_maps

        # Next, we check if the tzid is somewhere in our tzid map.

        return ActiveSupport::TimeZone.new(@map[tzid]) if @map.key?(tzid)

        # Maybe the author was hyper-lazy and just included an offset. We
        # support it, but we aren't happy about it.
        matches = /^GMT(\+|-)([0-9]{4})$/.match(tzid)
        if matches

          # Note that the path in the source will never be taken from PHP 5.5.10
          # onwards. PHP 5.5.10 supports the "GMT+0100" style of format, so it
          # already gets returned early in this function. Once we drop support
          # for versions under PHP 5.5.10, this bit can be taken out of the
          # source.
          # @codeCoverageIgnoreStart
          return ActiveSupport::TimeZone.new("Etc/GMT#{matches[1]}#{matches[2][0..1].gsub(/^0+/, '')}")
          # @codeCoverageIgnoreEnd
        end

        if vcalendar
          # If that didn't work, we will scan VTIMEZONE objects
          vcalendar.select('VTIMEZONE').each do |vtimezone|
            next unless vtimezone['TZID'].to_s == tzid
            if vtimezone.key?('X-LIC-LOCATION')
              lic = vtimezone['X-LIC-LOCATION'].to_s

              # Libical generators may specify strings like
              # "SystemV/EST5EDT". For those we must remove the
              # SystemV part.
              lic = lic[8..-1] if lic[0...8] == 'SystemV/'

              return time_zone(lic, nil, fail_if_uncertain)
            end

            # Microsoft may add a magic number, which we also have an
            # answer for.
            next unless vtimezone.key?('X-MICROSOFT-CDO-TZID')
            cdo_id = vtimezone['X-MICROSOFT-CDO-TZID'].value.to_i

            # 2 can mean both Europe/Lisbon and Europe/Sarajevo.
            if cdo_id == 2 && vtimezone['TZID'].to_s.index('Sarajevo')
              return ActiveSupport::TimeZone.new('Europe/Sarajevo')
            end

            if @microsoft_exchange_map.key?(cdo_id)
              return ActiveSupport::TimeZone.new(@microsoft_exchange_map[cdo_id])
            end
          end
        end

        if fail_if_uncertain
          fail ArgumentError, "We were unable to determine the correct PHP timezone for tzid: #{tzid}"
        end

        # If we got all the way here, we default to UTC.
        Time.zone
      end

      # This method will load in all the tz mapping information, if it's not yet
      # done.
      def self.load_tz_maps
        return @map if @map

        @map = TimeZoneData::PhpZones.list
        @map.merge!(TimeZoneData::ExchangeZones.list)
        @map.merge!(TimeZoneData::LotusZones.list)
        @map.merge!(TimeZoneData::WindowsZones.list)
        @map
      end

      class << self
        attr_accessor :map
        attr_accessor :microsoft_exchange_map
      end
    end
  end
end
