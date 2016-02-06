require 'base64'
module Tilia
  module VObject
    # This utility converts vcards from one version to another.
    class VCardConverter
      # Converts a vCard object to a new version.
      #
      # targetVersion must be one of:
      #   Document::VCARD21
      #   Document::VCARD30
      #   Document::VCARD40
      #
      # Currently only 3.0 and 4.0 as input and output versions.
      #
      # 2.1 has some minor support for the input version, it's incomplete at the
      # moment though.
      #
      # If input and output version are identical, a clone is returned.
      #
      # @param Component\VCard input
      # @param int target_version
      def convert(input, target_version)
        input_version = input.document_type
        return input.dup if input_version == target_version

        unless [Tilia::VObject::Document::VCARD21, Tilia::VObject::Document::VCARD30, Tilia::VObject::Document::VCARD40].include? input_version
          fail ArgumentError, 'Only vCard 2.1, 3.0 and 4.0 are supported for the input data'
        end
        unless [Tilia::VObject::Document::VCARD30, Tilia::VObject::Document::VCARD40].include? target_version
          fail ArgumentError, 'You can only use vCard 3.0 or 4.0 for the target version'
        end

        new_version = target_version == Tilia::VObject::Document::VCARD40 ? '4.0' : '3.0'

        output = Tilia::VObject::Component::VCard.new('VERSION' => new_version)

        # We might have generated a default UID. Remove it!
        output.delete('UID')

        input.children.each do |property|
          convert_property(input, output, property, target_version)
        end

        output
      end

      protected

      # Handles conversion of a single property.
      #
      # @param Component\VCard input
      # @param Component\VCard output
      # @param Property property
      # @param int target_version
      #
      # @return void
      def convert_property(input, output, property, target_version)
        # Skipping these, those are automatically added.
        return nil if %w(VERSION PRODID).include?(property.name)

        parameters = property.parameters
        value_type = nil
        if parameters.key?('VALUE')
          value_type = parameters['VALUE'].value
          parameters.delete('VALUE')
        end

        value_type = property.value_type unless value_type

        new_property = output.create_property(
          property.name,
          property.parts,
          {}, # parameters will get added a bit later.
          value_type
        )

        if target_version == Tilia::VObject::Document::VCARD30
          if property.is_a?(Tilia::VObject::Property::Uri) && %w(PHOTO LOGO SOUND).include?(property.name)
            new_property = convert_uri_to_binary(output, new_property)
          elsif property.is_a? Tilia::VObject::Property::VCard::DateAndOrTime
            # In vCard 4, the birth year may be optional. This is not the
            # case for vCard 3. Apple has a workaround for this that
            # allows applications that support Apple's extension still
            # omit birthyears in vCard 3, but applications that do not
            # support this, will just use a random birthyear. We're
            # choosing 1604 for the birthyear, because that's what apple
            # uses.
            parts = Tilia::VObject::DateTimeParser.parse_v_card_date_time(property.value)
            if parts['year'].nil?
              new_value = format('1604-%02i-%02i', parts['month'].to_i, parts['date'].to_i)
              new_property.value = new_value
              new_property['X-APPLE-OMIT-YEAR'] = '1604'
            end

            if new_property.name == 'ANNIVERSARY'
              # Microsoft non-standard anniversary
              new_property.name = 'X-ANNIVERSARY'

              # We also need to add a new apple property for the same
              # purpose. This apple property needs a 'label' in the same
              # group, so we first need to find a groupname that doesn't
              # exist yet.
              x = 1
              loop do
                break if output.select("ITEM#{x}.").empty?
                x += 1
              end
              output.add("ITEM#{x}.X-ABDATE", new_property.value, 'VALUE' => 'DATE-AND-OR-TIME')
              output.add("ITEM#{x}.X-ABLABEL", '_$!<Anniversary>!$_')
            end
          elsif property.name == 'KIND'
            case property.value.downcase
            when 'org'
              # vCard 3.0 does not have an equivalent to KIND:ORG,
              # but apple has an extension that means the same
              # thing.
              new_property = output.create_property('X-ABSHOWAS', 'COMPANY')
            when 'individual'
              # Individual is implicit, so we skip it.
              return nil
            when 'group'
              # OS X addressbook property
              new_property = output.create_property('X-ADDRESSBOOKSERVER-KIND', 'GROUP')
            end
          end
        elsif target_version == Tilia::VObject::Document::VCARD40
          # These properties were removed in vCard 4.0
          return nil if %w(NAME MAILER LABEL CLASS).include?(property.name)

          if property.is_a?(Tilia::VObject::Property::Binary)
            new_property = convert_binary_to_uri(output, new_property, parameters)
          elsif property.is_a?(Tilia::VObject::Property::VCard::DateAndOrTime) && parameters.key?('X-APPLE-OMIT-YEAR')
            # If a property such as BDAY contained 'X-APPLE-OMIT-YEAR',
            # then we're stripping the year from the vcard 4 value.
            parts = Tilia::VObject::DateTimeParser.parse_v_card_date_time(property.value)
            if parts['year'] == property['X-APPLE-OMIT-YEAR'].value.to_i
              new_value = format('--%02i-%02i', parts['month'], parts['date'])
              new_property.value = new_value
            end

            # Regardless if the year matched or not, we do need to strip
            # X-APPLE-OMIT-YEAR.
            parameters.delete('X-APPLE-OMIT-YEAR')
          end

          case property.name
          when 'X-ABSHOWAS'
            if property.value.upcase == 'COMPANY'
              new_property = output.create_property('KIND', 'ORG')
            end
          when 'X-ADDRESSBOOKSERVER-KIND'
            if property.value.upcase == 'GROUP'
              new_property = output.create_property('KIND', 'GROUP')
            end
          when 'X-ANNIVERSARY'
            new_property.name = 'ANNIVERSARY'
            # If we already have an anniversary property with the same
            # value, ignore.
            output.select('ANNIVERSARY').each do |anniversary|
              return nil if anniversary.value == new_property.value
            end
          when 'X-ABDATE'
            # Find out what the label was, if it exists.
            label = input["#{property.group}.X-ABLABEL"]

            # We only support converting anniversaries.
            if property.group && label && label.value == '_$!<Anniversary>!$_'
              # If we already have an anniversary property with the same
              # value, ignore.
              output.select('ANNIVERSARY').each do |anniversary|
                return nil if anniversary.value == new_property.value
              end
              new_property.name = 'ANNIVERSARY'
            end
          # Apple's per-property label system.
          when 'X-ABLABEL'
            if new_property.value == '_$!<Anniversary>!$_'
              # We can safely remove these, as they are converted to
              # ANNIVERSARY properties.
              return nil
            end
          end
        end

        # set property group
        new_property.group = property.group

        if target_version == Tilia::VObject::Document::VCARD40
          convert_parameters40(new_property, parameters)
        else
          convert_parameters30(new_property, parameters)
        end

        # Lastly, we need to see if there's a need for a VALUE parameter.
        #
        # We can do that by instantating a empty property with that name, and
        # seeing if the default valueType is identical to the current one.
        temp_property = output.create_property(new_property.name)
        if temp_property.value_type != new_property.value_type
          new_property['VALUE'] = new_property.value_type
        end

        output.add(new_property)
      end

      # Converts a BINARY property to a URI property.
      #
      # vCard 4.0 no longer supports BINARY properties.
      #
      # @param Component\VCard output
      # @param Tilia::VObject::Property::Uri property The input property.
      # @param parameters List of parameters that will eventually be added to
      #                    the new property.
      #
      # @return Tilia::VObject::Property::Uri
      def convert_binary_to_uri(output, new_property, parameters)
        value = new_property.value
        new_property = output.create_property(
          new_property.name,
          nil, # no value
          {}, # no parameters yet
          'URI' # Forcing the BINARY type
        )

        mime_type = 'application/octet-stream'

        # See if we can find a better mimetype.
        if parameters.key?('TYPE')
          new_types = []
          parameters['TYPE'].parts.each do |type_part|
            if %w(JPEG PNG GIF).include?(type_part.upcase)
              mime_type = "image/#{type_part.downcase}"
            else
              new_types << type_part
            end
          end

          # If there were any parameters we're not converting to a
          # mime-type, we need to keep them.
          if new_types.any?
            parameters['TYPE'].parts = new_types
          else
            parameters.delete('TYPE')
          end
        end

        new_property.value = "data:#{mime_type};base64,#{Base64.strict_encode64(value)}"
        new_property
      end

      # Converts a URI property to a BINARY property.
      #
      # In vCard 4.0 attachments are encoded as data: uri. Even though these may
      # be valid in vCard 3.0 as well, we should convert those to BINARY if
      # possible, to improve compatibility.
      #
      # @param Component\VCard output
      # @param Tilia::VObject::Property::Uri property The input property.
      #
      # @return Tilia::VObject::Property::Binary|null
      def convert_uri_to_binary(output, new_property)
        value = new_property.value

        # Only converting data: uris
        return new_property if value[0...5] != 'data:'

        new_property = output.create_property(
          new_property.name,
          nil, # no value
          {}, # no parameters yet
          'BINARY'
        )

        mime_type = value[5...value.index(',')]
        if mime_type.index(';')
          mime_type = mime_type[0...mime_type.index(';')]
          new_property.value = Base64.decode64(value[value.index(',') + 1..-1])
        else
          new_property.value = value[value.index(',') + 1..-1]
        end

        new_property['ENCODING'] = 'b'
        case mime_type
        when 'image/jpeg'
          new_property['TYPE'] = 'JPEG'
        when 'image/png'
          new_property['TYPE'] = 'PNG'
        when 'image/gif'
          new_property['TYPE'] = 'GIF'
        end

        new_property
      end

      # Adds parameters to a new property for vCard 4.0.
      #
      # @param Property new_property
      # @param array parameters
      #
      # @return void
      def convert_parameters40(new_property, parameters)
        # Adding all parameters.
        parameters.each do |_, param|
          # vCard 2.1 allowed parameters with no name
          param.no_name = false if param.no_name

          case param.name
          # We need to see if there's any TYPE=PREF, because in vCard 4
          # that's now PREF=1.
          when 'TYPE'
            param.parts.each do |param_part|
              if param_part.upcase == 'PREF'
                new_property.add('PREF', '1')
              else
                new_property.add(param.name, param_part)
              end
            end
          when 'ENCODING', 'CHARSET'
            # These no longer exist in vCard 4
          else
            new_property.add(param.name, param.parts)
          end
        end
      end

      # Adds parameters to a new property for vCard 3.0.
      #
      # @param Property new_property
      # @param array parameters
      #
      # @return void
      def convert_parameters30(new_property, parameters)
        # Adding all parameters.
        parameters.each do |_, param|
          # vCard 2.1 allowed parameters with no name
          param.no_name = false if param.no_name

          case param.name
          when 'ENCODING'
            # This value only existed in vCard 2.1, and should be
            # removed for anything else.
            if param.value.upcase != 'QUOTED-PRINTABLE'
              new_property.add(param.name, param.parts)
            end
          # Converting PREF=1 to TYPE=PREF.
          #
          # Any other PREF numbers we'll drop.
          when 'PREF'
            new_property.add('TYPE', 'PREF') if param.value == '1'
          else
            new_property.add(param.name, param.parts)
          end
        end
      end
    end
  end
end
