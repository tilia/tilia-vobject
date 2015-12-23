module Tilia
  module VObject
    class CliMock < Cli
      attr_accessor :quiet
      attr_accessor :format
      attr_accessor :pretty
      attr_accessor :stdin
      attr_accessor :stdout
      attr_accessor :stderr
      attr_accessor :input_format
      attr_accessor :output_format

      def initialize
        super
        @quiet = false
      end
    end
  end
end
