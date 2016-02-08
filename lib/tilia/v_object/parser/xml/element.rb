module Tilia
  module VObject
    module Parser
      class Xml
        # Implementation of our own Tilia::Xml::Element classes
        module Element
          require 'tilia/v_object/parser/xml/element/key_value'
        end
      end
    end
  end
end
