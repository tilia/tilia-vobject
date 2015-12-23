module Tilia
  module VObject
    # FreeBusyData is a helper class that manages freebusy information.
    class FreeBusyData
      # Start timestamp
      #
      # @var int
      # RUBY: attr_accessor :start

      # End timestamp
      #
      # @var int
      # RUBY: attr_accessor :end

      # A list of free-busy times.
      #
      # @var array
      # RUBY: attr_accessor :data

      def initialize(start, ending)
        @start = start
        @end = ending
        @data = []

        @data << {
          'start' => @start,
          'end'   => @end,
          'type'  => 'FREE'
        }
      end

      # Adds free or busytime to the data.
      #
      # @param int start
      # @param int end
      # @param string type FREE, BUSY, BUSY-UNAVAILABLE or BUSY-TENTATIVE
      # @return void
      def add(start, ending, type)
        if start > @end || ending < @start
          # This new data is outside our timerange.
          return nil
        end

        if start < @start
          # The item starts before our requested time range
          start = @start
        end
        if ending > @end
          # The item ends after our requested time range
          ending = @end
        end

        # Finding out where we need to insert the new item.
        current_index = 0
        current_index += 1 while start > @data[current_index]['end']

        # The standard insertion point will be one _after_ the first
        # overlapping item.
        insert_start_index = current_index + 1

        new_item = {
          'start' => start,
          'end'   => ending,
          'type'  => type
        }

        preceeding_item = @data[insert_start_index - 1]
        if @data[insert_start_index - 1]['start'] == start
          # The old item starts at the exact same point as the new item.
          insert_start_index -= 1
        end

        # Now we know where to insert the item, we need to know where it
        # starts overlapping with items on the tail end. We need to start
        # looking one item before the insertStartIndex, because it's possible
        # that the new item 'sits inside' the previous old item.
        if insert_start_index > 0
          current_index = insert_start_index - 1
        else
          current_index = 0
        end

        current_index += 1 while ending > @data[current_index]['end']

        # What we are about to insert into the array
        new_items = [new_item]

        # This is the amount of items that are completely overwritten by the
        # new item.
        items_to_delete = current_index - insert_start_index
        items_to_delete += 1 if @data[current_index]['end'] <= ending

        # If itemsToDelete was -1, it means that the newly inserted item is
        # actually sitting inside an existing one. This means we need to split
        # the item at the current position in two and insert the new item in
        # between.
        if items_to_delete == -1
          items_to_delete = 0
          if new_item['end'] < preceeding_item['end']
            new_items << {
              'start' => new_item['end'] + 1,
              'end'   => preceeding_item['end'],
              'type'  => preceeding_item['type']
            }
          end
        end

        @data[insert_start_index, items_to_delete] = new_items

        do_merge = false
        merge_offset = insert_start_index
        merge_item = new_item
        merge_delete = 1

        # Ruby knows negative indices as well!
        if insert_start_index > 0 && @data.size > insert_start_index - 1
          # Updating the start time of the previous item.
          @data[insert_start_index - 1]['end'] = start

          # If the previous and the current are of the same type, we can
          # merge them into one item.
          if @data[insert_start_index - 1]['type'] == @data[insert_start_index]['type']
            do_merge = true
            merge_offset -= 1
            merge_delete += 1
            merge_item['start'] = @data[insert_start_index - 1]['start']
          end
        end

        if @data.size > insert_start_index + 1
          # Updating the start time of the next item.
          @data[insert_start_index + 1]['start'] = ending

          # If the next and the current are of the same type, we can
          # merge them into one item.
          if @data[insert_start_index + 1]['type'] == @data[insert_start_index]['type']
            do_merge = true
            merge_delete += 1
            merge_item['end'] = @data[insert_start_index + 1]['end']
          end
        end

        @data[merge_offset, merge_delete] = merge_item if do_merge
      end

      attr_reader :data
    end
  end
end
