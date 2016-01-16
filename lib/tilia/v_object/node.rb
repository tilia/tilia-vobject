module Tilia
  module VObject
    # A node is the root class for every element in an iCalendar of vCard object.
    class Node
      include Tilia::Xml::XmlSerializable
      include Enumerable

      # The following constants are used by the validate method.
      #
      # If REPAIR is set, the validator will attempt to repair any broken data
      # (if possible).
      REPAIR = 1

      # If this option is set, the validator will operate on the vcards on the
      # assumption that the vcards need to be valid for CardDAV.
      #
      # This means for example that the UID is required, whereas it is not for
      # regular vcards.
      PROFILE_CARDDAV = 2

      # If this option is set, the validator will operate on iCalendar objects
      # on the assumption that the vcards need to be valid for CalDAV.
      #
      # This means for example that calendars can only contain objects with
      # identical component types and UIDs.
      PROFILE_CALDAV = 4

      # Reference to the parent object, if this is not the top object.
      #
      # @var Node
      attr_accessor :parent

      # The root document.
      #
      # @var Component
      # RUBY: attr_accessor :root

      # Serializes the node into a mimedir format.
      #
      # @return string
      def serialize
      end

      # This method returns an array, with the representation as it should be
      # encoded in JSON. This is used to create jCard or jCal documents.
      #
      # @return array
      def json_serialize
      end

      # This method serializes the data into XML. This is used to create xCard or
      # xCal documents.
      #
      # @param Xml\Writer writer  XML writer.
      #
      # @return void
      def xml_serialize(_writer)
      end

      # Call this method on a document if you're done using it.
      #
      # It's intended to remove all circular references, so PHP can easily clean
      # it up.
      #
      # @return void
      def destroy
        @parent = nil
        @root = nil
      end

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
      def validate(_options = 0)
        []
      end

      # Returns the iterator for this object.
      #
      # @return ElementList
      def iterator
        return @iterator if @iterator

        ElementList.new([self])
      end

      # Sets the overridden iterator.
      #
      # Note that this is not actually part of the iterator interface
      #
      # @param ElementList $iterator
      #
      # @return void
      attr_writer :iterator

      # Returns the number of elements.
      #
      # @return int
      def size
        it = iterator
        it.size
      end
      alias_method :length, :size
      alias_method :count, :size

      # Checks if an item exists through ArrayAccess.
      #
      # This method just forwards the request to the inner iterator
      #
      # @param int $offset
      #
      # @return bool
      def key?(offset)
        iterator = self.iterator
        iterator.key?(offset)
      end

      # Gets an item through ArrayAccess.
      #
      # This method just forwards the request to the inner iterator
      #
      # @param int $offset
      #
      # @return mixed
      def [](offset)
        iterator = self.iterator
        iterator[offset]
      end

      # Sets an item through ArrayAccess.
      #
      # This method just forwards the request to the inner iterator
      #
      # @param int $offset
      # @param mixed $value
      #
      # @return void
      def []=(offset, value)
        iterator = self.iterator
        iterator[offset] = value
      end

      # Sets an item through ArrayAccess.
      #
      # This method just forwards the request to the inner iterator
      #
      # @param int $offset
      #
      # @return void
      def delete(offset)
        iterator = self.iterator
        iterator.delete(offset)
      end

      def initialize
        @root = nil
      end

      def each
        iterator = self.iterator
        iterator.each { |i| yield(i) }
      end

      def ==(other)
        return true if other.__id__ == __id__

        # check class
        return false unless self.class == other.class

        # Instance variables should be the same
        return false unless instance_variables.sort == other.instance_variables.sort

        # compare all instance variables
        instance_variables.each do |var|
          if var == :@root && instance_variable_get(var) == self
            # We are our own root
            return false unless other.instance_variable_get(var) == other
          else
            return false unless instance_variable_get(var) == other.instance_variable_get(var)
          end
        end
        true
      end
    end
  end
end
