require 'test_helper'

module Tilia
  module VObject
    class FreeBusyDataTest < Minitest::Test
      def test_get_data
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end

      def test_add_beginning
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        # Overwriting the first half
        fb.add(100, 150, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 150,
              'type'  => 'BUSY'
            },
            {
              'start' => 150,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )

        # Overwriting the first half again
        fb.add(100, 150, 'BUSY-TENTATIVE')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 150,
              'type'  => 'BUSY-TENTATIVE'
            },
            {
              'start' => 150,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end

      def test_add_end
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        # Overwriting the first half
        fb.add(150, 200, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 150,
              'type'  => 'FREE'
            },
            {
              'start' => 150,
              'end'   => 200,
              'type'  => 'BUSY'
            }
          ],
          fb.data
        )
      end

      def test_add_middle
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        # Overwriting the first half
        fb.add(150, 160, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 150,
              'type'  => 'FREE'
            },
            {
              'start' => 150,
              'end'   => 160,
              'type'  => 'BUSY'
            },
            {
              'start' => 160,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end

      def test_add_multiple
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        fb.add(110, 120, 'BUSY')
        fb.add(130, 140, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 110,
              'type'  => 'FREE'
            },
            {
              'start' => 110,
              'end'   => 120,
              'type'  => 'BUSY'
            },
            {
              'start' => 120,
              'end'   => 130,
              'type'  => 'FREE'
            },
            {
              'start' => 130,
              'end'   => 140,
              'type'  => 'BUSY'
            },
            {
              'start' => 140,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end

      def test_add_multiple_overlap
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        fb.add(110, 120, 'BUSY')
        fb.add(130, 140, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 110,
              'type'  => 'FREE'
            },
            {
              'start' => 110,
              'end'   => 120,
              'type'  => 'BUSY'
            },
            {
              'start' => 120,
              'end'   => 130,
              'type'  => 'FREE'
            },
            {
              'start' => 130,
              'end'   => 140,
              'type'  => 'BUSY'
            },
            {
              'start' => 140,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )

        fb.add(115, 135, 'BUSY-TENTATIVE')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 110,
              'type'  => 'FREE'
            },
            {
              'start' => 110,
              'end'   => 115,
              'type'  => 'BUSY'
            },
            {
              'start' => 115,
              'end'   => 135,
              'type'  => 'BUSY-TENTATIVE'
            },
            {
              'start' => 135,
              'end'   => 140,
              'type'  => 'BUSY'
            },
            {
              'start' => 140,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end

      def test_add_multiple_overlap_and_merge
        fb = Tilia::VObject::FreeBusyData.new(100, 200)

        fb.add(110, 120, 'BUSY')
        fb.add(130, 140, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 110,
              'type'  => 'FREE'
            },
            {
              'start' => 110,
              'end'   => 120,
              'type'  => 'BUSY'
            },
            {
              'start' => 120,
              'end'   => 130,
              'type'  => 'FREE'
            },
            {
              'start' => 130,
              'end'   => 140,
              'type'  => 'BUSY'
            },
            {
              'start' => 140,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )

        fb.add(115, 135, 'BUSY')

        assert_equal(
          [
            {
              'start' => 100,
              'end'   => 110,
              'type'  => 'FREE'
            },
            {
              'start' => 110,
              'end'   => 140,
              'type'  => 'BUSY'
            },
            {
              'start' => 140,
              'end'   => 200,
              'type'  => 'FREE'
            }
          ],
          fb.data
        )
      end
    end
  end
end
