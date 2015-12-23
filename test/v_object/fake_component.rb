module Tilia
  module VObject
    class FakeComponent < Component
      def validation_rules
        {
          'FOO' => '0',
          'BAR' => '1',
          'BAZ' => '+',
          'ZIM' => '*',
          'GIR' => '?'
        }
      end

      def defaults
        {
          'BAR' => 'yow'
        }
      end
    end
  end
end
