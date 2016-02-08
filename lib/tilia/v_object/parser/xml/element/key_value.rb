module Tilia
  module VObject
    module Parser
      class Xml
        module Element
          # Our own sabre/xml key-value element.
          #
          # It just removes the clark notation.
          class KeyValue < Tilia::Xml::Element::KeyValue
            # The deserialize method is called during xml parsing.
            #
            # This method is called staticly, this is because in theory this method
            # may be used as a type of constructor, or factory method.
            #
            # Often you want to return an instance of the current class, but you are
            # free to return other data as well.
            #
            # Important note 2: You are responsible for advancing the reader to the
            # next element. Not doing anything will result in a never-ending loop.
            #
            # If you just want to skip parsing for this element altogether, you can
            # just call reader.next
            #
            # reader.parse_inner_tree will parse the entire sub-tree, and advance to
            # the next element.
            #
            # @param [XML\Reader] reader
            #
            # @return [mixed]
            def self.xml_deserialize(reader)
              # If there's no children, we don't do anything.
              if reader.empty_element?
                reader.next
                return {}
              end

              values = {}
              reader.read

              loop do
                if reader.node_type == ::LibXML::XML::Reader::TYPE_ELEMENT
                  name = reader.local_name
                  values[name] = reader.parse_current_element['value']
                else
                  reader.read
                end

                break if reader.node_type == ::LibXML::XML::Reader::TYPE_END_ELEMENT
              end

              reader.read

              values
            end
          end
        end
      end
    end
  end
end
