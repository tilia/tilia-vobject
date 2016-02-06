module Tilia
  module VObject
    class Component
      # The VCard component.
      #
      # This component represents the BEGIN:VCARD and END:VCARD found in every
      # vcard.
      class VCard < Document
        # The default name for this component.
        #
        # This should be 'VCALENDAR' or 'VCARD'.
        #
        # @var string
        @default_name = 'VCARD'

        # This is a list of components, and which classes they should map to.
        #
        # @var array
        @component_map = {
          'VCARD' => Component::VCard
        }

        # List of value-types, and which classes they map to.
        #
        # @var array
        @value_map = {
          'BINARY'           => Property::Binary,
          'BOOLEAN'          => Property::Boolean,
          'CONTENT-ID'       => Property::FlatText, # vCard 2.1 only
          'DATE'             => Property::VCard::Date,
          'DATE-TIME'        => Property::VCard::DateTime,
          'DATE-AND-OR-TIME' => Property::VCard::DateAndOrTime, # vCard only
          'FLOAT'            => Property::FloatValue,
          'INTEGER'          => Property::IntegerValue,
          'LANGUAGE-TAG'     => Property::VCard::LanguageTag,
          'TIMESTAMP'        => Property::VCard::TimeStamp,
          'TEXT'             => Property::Text,
          'TIME'             => Property::Time,
          'UNKNOWN'          => Property::Unknown, # jCard / jCal-only.
          'URI'              => Property::Uri,
          'URL'              => Property::Uri, # vCard 2.1 only
          'UTC-OFFSET'       => Property::UtcOffset
        }

        # List of properties, and which classes they map to.
        #
        # @var array
        @property_map = {
          # vCard 2.1 properties and up
          'N'       => Property::Text,
          'FN'      => Property::FlatText,
          'PHOTO'   => Property::Binary,
          'BDAY'    => Property::VCard::DateAndOrTime,
          'ADR'     => Property::Text,
          'LABEL'   => Property::FlatText, # Removed in vCard 4.0
          'TEL'     => Property::FlatText,
          'EMAIL'   => Property::FlatText,
          'MAILER'  => Property::FlatText, # Removed in vCard 4.0
          'GEO'     => Property::FlatText,
          'TITLE'   => Property::FlatText,
          'ROLE'    => Property::FlatText,
          'LOGO'    => Property::Binary,
          # 'AGENT'   => Property::,      // Todo: is an embedded vCard. Probably rare, so
          # not supported at the moment
          'ORG'     => Property::Text,
          'NOTE'    => Property::FlatText,
          'REV'     => Property::VCard::TimeStamp,
          'SOUND'   => Property::FlatText,
          'URL'     => Property::Uri,
          'UID'     => Property::FlatText,
          'VERSION' => Property::FlatText,
          'KEY'     => Property::FlatText,
          'TZ'      => Property::Text,

          # vCard 3.0 properties
          'CATEGORIES'  => Property::Text,
          'SORT-STRING' => Property::FlatText,
          'PRODID'      => Property::FlatText,
          'NICKNAME'    => Property::Text,
          'CLASS'       => Property::FlatText, # Removed in vCard 4.0

          # rfc2739 properties
          'FBURL'        => Property::Uri,
          'CAPURI'       => Property::Uri,
          'CALURI'       => Property::Uri,
          'CALADRURI'    => Property::Uri,

          # rfc4770 properties
          'IMPP'         => Property::Uri,

          # vCard 4.0 properties
          'SOURCE'       => Property::Uri,
          'XML'          => Property::FlatText,
          'ANNIVERSARY'  => Property::VCard::DateAndOrTime,
          'CLIENTPIDMAP' => Property::Text,
          'LANG'         => Property::VCard::LanguageTag,
          'GENDER'       => Property::Text,
          'KIND'         => Property::FlatText,
          'MEMBER'       => Property::Uri,
          'RELATED'      => Property::Uri,

          # rfc6474 properties
          'BIRTHPLACE'    => Property::FlatText,
          'DEATHPLACE'    => Property::FlatText,
          'DEATHDATE'     => Property::VCard::DateAndOrTime,

          # rfc6715 properties
          'EXPERTISE'     => Property::FlatText,
          'HOBBY'         => Property::FlatText,
          'INTEREST'      => Property::FlatText,
          'ORG-DIRECTORY' => Property::FlatText
        }

        # Returns the current document type.
        #
        # @return int
        def document_type
          unless @version
            version = self['VERSION'].to_s

            case version
            when '2.1'
              @version = VCARD21
            when '3.0'
              @version = VCARD30
            when '4.0'
              @version = VCARD40
            else
              # We don't want to cache the version if it's unknown,
              # because we might get a version property in a bit.
              return UNKNOWN
            end
          end

          @version
        end

        # Converts the document to a different vcard version.
        #
        # Use one of the VCARD constants for the target. This method will return
        # a copy of the vcard in the new version.
        #
        # At the moment the only supported conversion is from 3.0 to 4.0.
        #
        # If input and output version are identical, a clone is returned.
        #
        # @param int target
        #
        # @return VCard
        def convert(target)
          converter = VCardConverter.new
          converter.convert(self, target)
        end

        # VCards with version 2.1, 3.0 and 4.0 are found.
        #
        # If the VCARD doesn't know its version, 2.1 is assumed.
        DEFAULT_VERSION = VCARD21

        # Validates the node for correctness.
        #
        # The following options are supported:
        #   Node::REPAIR - May attempt to automatically repair the problem.
        #
        # This method returns an array with detected problems.
        # Every element has the following properties:
        #
        #  * level - problem level.
        #  * message - A human-readable string describing the issue.
        #  * node - A reference to the problematic node.
        #
        # The level means:
        #   1 - The issue was repaired (only happens if REPAIR was turned on)
        #   2 - An inconsequential issue
        #   3 - A severe issue.
        #
        # @param int options
        #
        # @return array
        def validate(options = 0)
          warnings = []

          version_map = {
            VCARD21 => '2.1',
            VCARD30 => '3.0',
            VCARD40 => '4.0'
          }

          version = select('VERSION')
          if version.size == 1
            version = self['VERSION'].to_s
            unless ['2.1', '3.0', '4.0'].include?(version)
              warnings << {
                'level'   => 3,
                'message' => 'Only vcard version 4.0 (RFC6350), version 3.0 (RFC2426) or version 2.1 (icm-vcard-2.1) are supported.',
                'node'    => self
              }
              if options & REPAIR > 0
                self['VERSION'] = version_map[DEFAULT_VERSION]
              end
            end

            if version == '2.1' && options & PROFILE_CARDDAV > 0
              warnings << {
                'level'   => 3,
                'message' => 'CardDAV servers are not allowed to accept vCard 2.1.',
                'node'    => self
              }
            end
          end

          uid = select('UID')
          if uid.size == 0
            if options & PROFILE_CARDDAV > 0
              # Required for CardDAV
              warning_level = 3
              message = 'vCards on CardDAV servers MUST have a UID property.'
            else
              # Not required for regular vcards
              warning_level = 2
              message = 'Adding a UID to a vCard property is recommended.'
            end

            if options & REPAIR > 0
              self['UID'] = UuidUtil.uuid
              warning_level = 1
            end

            warnings << {
              'level'   => warning_level,
              'message' => message,
              'node'    => self
            }
          end

          fn = select('FN')
          if fn.size != 1
            repaired = false

            if options & REPAIR > 0 && fn.size == 0
              # We're going to try to see if we can use the contents of the
              # N property.
              if key?('N')
                value = self['N'].to_s.split(';')
                if value[1]
                  self['FN'] = value[1] + ' ' + value[0]
                else
                  self['FN'] = value[0]
                end

                repaired = true

              # Otherwise, the ORG property may work
              elsif key?('ORG')
                self['FN'] = self['ORG'].to_s
                repaired = true
              end
            end

            warnings << {
              'level'   => repaired ? 1 : 3,
              'message' => 'The FN property must appear in the VCARD component exactly 1 time',
              'node'    => self
            }
          end

          w = super(options)
          w.concat warnings

          w
        end

        # A simple list of validation rules.
        #
        # This is simply a list of properties, and how many times they either
        # must or must not appear.
        #
        # Possible values per property:
        #   * 0 - Must not appear.
        #   * 1 - Must appear exactly once.
        #   * + - Must appear at least once.
        #   * * - Can appear any number of times.
        #   * ? - May appear, but not more than once.
        #
        # @var array
        def validation_rules
          {
            'ADR'          => '*',
            'ANNIVERSARY'  => '?',
            'BDAY'         => '?',
            'CALADRURI'    => '*',
            'CALURI'       => '*',
            'CATEGORIES'   => '*',
            'CLIENTPIDMAP' => '*',
            'EMAIL'        => '*',
            'FBURL'        => '*',
            'IMPP'         => '*',
            'GENDER'       => '?',
            'GEO'          => '*',
            'KEY'          => '*',
            'KIND'         => '?',
            'LANG'         => '*',
            'LOGO'         => '*',
            'MEMBER'       => '*',
            'N'            => '?',
            'NICKNAME'     => '*',
            'NOTE'         => '*',
            'ORG'          => '*',
            'PHOTO'        => '*',
            'PRODID'       => '?',
            'RELATED'      => '*',
            'REV'          => '?',
            'ROLE'         => '*',
            'SOUND'        => '*',
            'SOURCE'       => '*',
            'TEL'          => '*',
            'TITLE'        => '*',
            'TZ'           => '*',
            'URL'          => '*',
            'VERSION'      => '1',
            'XML'          => '*',

            # FN is commented out, because it's already handled by the
            # validate function, which may also try to repair it.
            # 'FN'           => '+',
            'UID'          => '?'
          }
        end

        # Returns a preferred field.
        #
        # VCards can indicate wether a field such as ADR, TEL or EMAIL is
        # preferred by specifying TYPE=PREF (vcard 2.1, 3) or PREF=x (vcard 4, x
        # being a number between 1 and 100).
        #
        # If neither of those parameters are specified, the first is returned, if
        # a field with that name does not exist, null is returned.
        #
        # @param string field_name
        #
        # @return VObject\Property|null
        def preferred(property_name)
          preferred = nil
          last_pref = 101
          select(property_name).each do |field|
            pref = 101

            if field.key?('TYPE') && field['TYPE'].has('PREF')
              pref = 1
            elsif field.key?('PREF')
              pref = field['PREF'].value.to_i
            end

            if pref < last_pref || preferred.nil?
              preferred = field
              last_pref = pref
            end
          end

          preferred
        end

        protected

        # This method should return a list of default property values.
        #
        # @return array
        def defaults
          {
            'VERSION' => '4.0',
            'PRODID'  => "-//Tilia//Tilia VObject #{Version::VERSION}//EN",
            'UID'     => "tilia-vobject-#{UuidUtil.uuid}"
          }
        end

        public

        # This method returns an array, with the representation as it should be
        # encoded in json. This is used to create jCard or jCal documents.
        #
        # @return array
        def json_serialize
          # A vcard does not have sub-components, so we're overriding this
          # method to remove that array element.
          properties = []

          children.each do |child|
            properties << child.json_serialize
          end

          [@name.downcase, properties]
        end

        # This method serializes the data into XML. This is used to create xCard or
        # xCal documents.
        #
        # @param Xml\Writer writer  XML writer.
        #
        # @return void
        def xml_serialize(writer)
          properties_by_group = {}

          children.each do |property|
            group = property.group

            properties_by_group[group] = [] unless properties_by_group[group]
            properties_by_group[group] << property
          end

          writer.start_element(@name.downcase)

          properties_by_group.each do |group, properties|
            unless group.blank?
              writer.start_element('group')
              writer.write_attribute('name', group.downcase)
            end

            properties.each do |property|
              case property.name
              when 'VERSION'
                next
              when 'XML'
                value = property.parts
                fragment = Tilia::Xml::Element::XmlFragment.new(value[0])
                writer.write(fragment)
              else
                property.xml_serialize(writer)
              end
            end

            writer.end_element unless group.blank?
          end

          writer.end_element
        end

        # Returns the default class for a property name.
        #
        # @param string property_name
        #
        # @return string
        def class_name_for_property_name(property_name)
          class_name = super(property_name)

          # In vCard 4, BINARY no longer exists, and we need URI instead.
          if class_name == Property::Binary && document_type == VCARD40
            return Property::Uri
          end

          class_name
        end

        def initialize(*args)
          super(*args)
          @version = nil
        end
      end
    end
  end
end
