require 'json'
module Tilia
  module VObject
    # This is the CLI interface for sabre-vobject.
    class Cli
      # No output.
      #
      # @return [Boolean]
      # RUBY: attr_accessor :quiet

      # Help display.
      #
      # @return [Boolean]
      # RUBY: attr_accessor :show_help

      # Wether to spit out 'mimedir' or 'json' format.
      #
      # @return [String]
      # RUBY: attr_accessor :format

      # JSON pretty print.
      #
      # @return [Boolean]
      # RUBY: attr_accessor :pretty

      # Source file.
      #
      # @return [String]
      # RUBY: attr_accessor :input_path

      # Destination file.
      #
      # @return [String]
      # RUBY: attr_accessor :output_path

      # output stream.
      #
      # @return [resource]
      # RUBY: attr_accessor :stdout

      # stdin.
      #
      # @return [resource]
      # RUBY: attr_accessor :stdin

      # stderr.
      #
      # @return [resource]
      # RUBY: attr_accessor :stderr

      # Input format (one of json or mimedir).
      #
      # @return [String]
      # RUBY: attr_accessor :input_format

      # Makes the parser less strict.
      #
      # @return [Boolean]
      # RUBY: attr_accessor :forgiving

      # Main function.
      #
      # @return [Integer]
      def main(argv)
        # @codeCoverageIgnoreStart
        # We cannot easily test this, so we'll skip it. Pretty basic anyway.

        @stderr = STDERR unless @stderr
        @stdout = STDOUT unless @stdout
        @stdin = STDIN unless @stdin

        begin
          (options, positional) = parse_arguments(argv)

          @quiet = true if options['q']
          log(colorize('green', 'tilia/vobject ') + colorize('yellow', Version::VERSION))

          options.each do |name, value|
            case name
            when 'q'
            when 'h', 'help'
              show_help
              return 0
            when 'format'
              formats = %w(jcard jcal vcard21 vcard30 vcard40 icalendar20 json mimedir icalendar vcard)
              fail ArgumentError, "Unkown format: #{value}" unless formats.include?(value)
              @format = value
            when 'pretty'
              @pretty = true
            when 'forgiving'
              @forgiving = true
            when 'inputformat'
              case value
              # json formats
              when 'jcard', 'jcal', 'json'
                @input_format = 'json'
              # mimedir formats
              when 'mimedir', 'icalendar', 'vcard', 'vcard21', 'vcard30', 'vcard40', 'icalendar20'
                @input_format = 'mimedir'
              else
                fail ArgumentError, "Unknown format: #{value}"
              end
            end
          end

          if positional.empty?
            show_help
            return 1
          end

          if positional.size == 1
            fail ArgumentError, 'Inputfile is a required argument'
          end

          fail ArgumentError, 'Too many arguments' if positional.size > 3

          unless %w(validate repair convert color).include?(positional[0])
            fail ArgumentError, "Uknown command: #{positional[0]}"
          end
        rescue ArgumentError => e
          show_help
          log("Error: #{e}", 'red')
          return 1
        end

        command = positional[0]

        @input_path = positional[1]
        @output_path = positional[2] ? positional[2] : '-'

        @stdout = File.open(@output_path, 'w') if @output_path != '-'

        unless @input_format
          if @input_path[-5..-1] == '.json'
            @input_format = 'json'
          else
            @input_format = 'mimedir'
          end
        end

        unless @format
          if @output_path[-5..-1] == '.json'
            @format = 'json'
          else
            @format = 'mimedir'
          end
        end

        real_code = 0

        begin
          loop do
            input = read_input
            break unless input

            return_code = send(command, input)
            real_code = return_code unless return_code == 0
          end
        rescue EofException
          # end of file
          return real_code
        rescue StandardError => e
          log("Error: #{e}", 'red')
          return 2
        end

        real_code
      end

      protected

      # Shows the help message.
      #
      # @return [void]
      def show_help
        log('Usage:', 'yellow')
        log('  vobject [options] command [arguments]')
        log('')
        log('Options:', 'yellow')
        log(colorize('green', '  -q            ') + "Don't output anything.")
        log(colorize('green', '  -help -h      ') + 'Display this help message.')
        log(colorize('green', '  --format      ') + 'Convert to a specific format. Must be one of: vcard, vcard21,')
        log(colorize('green', '  --forgiving   ') + 'Makes the parser less strict.')
        log('                vcard30, vcard40, icalendar20, jcal, jcard, json, mimedir.')
        log(colorize('green', '  --inputformat ') + 'If the input format cannot be guessed from the extension, it')
        log('                must be specified here.')
        log(colorize('green', '  --pretty      ') + 'json pretty-print.')
        log('')
        log('Commands:', 'yellow')
        log(colorize('green', '  validate') + ' source_file              Validates a file for correctness.')
        log(colorize('green', '  repair') + ' source_file [output_file]  Repairs a file.')
        log(colorize('green', '  convert') + ' source_file [output_file] Converts a file.')
        log(colorize('green', '  color') + ' source_file                 Colorize a file, useful for debbugging.')
        log(
          <<HELP

If source_file is set as '-', STDIN will be used.
If output_file is omitted, STDOUT will be used.
All other output is sent to STDERR.
HELP
        )

        log('Examples:', 'yellow')
        log('   vobject convert contact.vcf contact.json')
        log('   vobject convert --format=vcard40 old.vcf new.vcf')
        log('   vobject convert --inputformat=json --format=mimedir - -')
        log('   vobject color calendar.ics')
        log('')
        log('https://github.com/fruux/sabre-vobject', 'purple')
      end

      # Validates a VObject file.
      #
      # @param [Component] v_obj
      #
      # @return [Integer]
      def validate(v_obj)
        return_code = 0

        case v_obj.name
        when 'VCALENDAR'
          log('iCalendar: ' + v_obj['VERSION'].to_s)
        when 'VCARD'
          log('vCard: ' + v_obj['VERSION'].to_s)
        end

        warnings = v_obj.validate
        if warnings.empty?
          log('  No warnings!')
        else
          levels = {
            1 => 'REPAIRED',
            2 => 'WARNING',
            3 => 'ERROR'
          }

          return_code = 2
          warnings.each do |warning|
            extra = ''
            if warning['node'].is_a?(Property)
              extra = ' (property: "' + warning['node'].name + '")'
            end
            log('  [' + levels[warning['level']] + '] ' + warning['message'] + extra)
          end
        end

        return_code
      end

      # Repairs a VObject file.
      #
      # @param [Component] v_obj
      #
      # @return [Integer]
      def repair(v_obj)
        return_code = 0

        case v_obj.name
        when 'VCALENDAR'
          log('iCalendar: ' + v_obj['VERSION'].to_s)
        when 'VCARD'
          log('vCard: ' + v_obj['VERSION'].to_s)
        end

        warnings = v_obj.validate(Node::REPAIR)
        if warnings.empty?
          log('  No warnings!')
        else
          levels = {
            1 => 'REPAIRED',
            2 => 'WARNING',
            3 => 'ERROR'
          }

          return_code = 2
          warnings.each do |warning|
            extra = ''
            if warning['node'].is_a?(Property)
              extra = ' (property: "' + warning['node'].name + '")'
            end
            log('  [' + levels[warning['level']] + '] ' + warning['message'] + extra)
          end
        end

        @stdout.write(v_obj.serialize)

        return_code
      end

      # Converts a vObject file to a new format.
      #
      # @param [Component] v_obj
      #
      # @return [Integer]
      def convert(v_obj)
        json = false
        convert_version = nil
        force_input = nil

        case @format
        when 'json'
          json = true
          convert_version = Document::VCARD40 if v_obj.name == 'VCARD'
        when 'jcard'
          json = true
          force_input = 'VCARD'
          convert_version = Document::VCARD40
        when 'jcal'
          json = true
          force_input = 'VCALENDAR'
        when 'mimedir', 'icalendar', 'icalendar20', 'vcard'
        when 'vcard21'
          convert_version = Document::VCARD21
        when 'vcard30'
          convert_version = Document::VCARD30
        when 'vcard40'
          convert_version = Document::VCARD40
        end

        if force_input && v_obj.name != force_input
          fail "You cannot convert a #{v_obj.name.downcase} to #{@format}"
        end

        v_obj = v_obj.convert(convert_version) if convert_version
        if json
          if @pretty
            @stdout.write(JSON.pretty_generate(v_obj.json_serialize))
          else
            @stdout.write(JSON.generate(v_obj.json_serialize))
          end
        else
          @stdout.write(v_obj.serialize)
        end

        0
      end

      # Colorizes a file.
      #
      # @param [Component] v_obj
      #
      # @return [Integer]
      def color(v_obj)
        @stdout.write(serialize_component(v_obj))
        0 # otherwise bytes written will be returned
      end

      # Returns an ansi color string for a color name.
      #
      # @param [String] color
      #
      # @return [String]
      def colorize(color, str, reset_to = 'default')
        colors = {
          'cyan'    => '1;36',
          'red'     => '1;31',
          'yellow'  => '1;33',
          'blue'    => '0;34',
          'green'   => '0;32',
          'default' => '0',
          'purple'  => '0;35'
        }
        "\033[#{colors[color]}m#{str}\033[#{colors[reset_to]}m"
      end

      # Writes out a string in specific color.
      #
      # @param [String] color
      # @param [String] str
      #
      # @return [void]
      def c_write(color, str)
        @stdout.write(colorize(color, str))
      end

      def serialize_component(v_obj)
        c_write('cyan', 'BEGIN')
        c_write('red', ':')
        c_write('yellow', v_obj.name + "\n")

        # Gives a component a 'score' for sorting purposes.
        #
        # This is solely used by the childrenSort method.
        #
        # A higher score means the item will be lower in the list.
        # To avoid score collisions, each "score category" has a reasonable
        # space to accomodate elements. The key is added to the score to
        # preserve the original relative order of elements.
        #
        # @param [Integer] key
        # @param [array] array
        #
        # @return [Integer]
        sort_score = lambda do |key, array|
          key = array.index(key)
          if array[key].is_a?(Component)
            # We want to encode VTIMEZONE first, this is a personal
            # preference.
            if array[key].name == 'VTIMEZONE'
              score = 300_000_000
              return score + key
            else
              score = 400_000_000
              return score + key
            end
          else
            # Properties get encoded first
            # VCARD version 4.0 wants the VERSION property to appear first
            if array[key].is_a?(Property)
              if array[key].name == 'VERSION'
                score = 100_000_000
                return score + key
              else
                # All other properties
                score = 200_000_000
                return score + key
              end
            end
          end
        end

        tmp = v_obj.children.sort do |a, b|
          s_a = sort_score.call(a, v_obj.children)
          s_b = sort_score.call(b, v_obj.children)
          s_a - s_b
        end

        tmp.each do |child|
          if child.is_a?(Component)
            serialize_component(child)
          else
            serialize_property(child)
          end
        end

        c_write('cyan', 'END')
        c_write('red', ':')
        c_write('yellow', v_obj.name + "\n")
      end

      # Colorizes a property.
      #
      # @param [Property] property
      #
      # @return [void]
      def serialize_property(property)
        if property.group
          c_write('default', property.group)
          c_write('red', '.')
        end

        c_write('yellow', property.name)

        property.parameters.each do |_, param|
          c_write('red', ';')
          c_write('blue', param.serialize)
        end

        c_write('red', ':')

        if property.is_a?(Property::Binary)
          c_write('default', "embedded binary stripped. (#{property.value.size} bytes)")
        else
          parts = property.parts
          first1 = true
          # Looping through property values
          parts.each do |part|
            if first1
              first1 = false
            else
              c_write('red', property.delimiter)
            end

            first2 = true
            # Looping through property sub-values
            part = [part] unless part.is_a?(Array)
            part.each do |sub_part|
              if first2
                first2 = false
              else
                # The sub-value delimiter is always comma
                c_write('red', ',')
              end

              sub_part = sub_part.gsub(
                /[\\;,\r\n]/,
                '\\' => colorize('purple', '\\\\', 'green'),
                ';'  => colorize('purple', '\\;', 'green'),
                ','  => colorize('purple', '\\,', 'green'),
                "\n" => colorize('purple', "\\n\n\t", 'green'),
                "\r" => ''
              )

              c_write('green', sub_part)
            end
          end
        end

        c_write('default', "\n")
      end

      # Parses the list of arguments.
      #
      # @param [array] argv
      #
      # @return [void]
      def parse_arguments(argv)
        positional = []
        options = {}

        ii = -1
        loop do
          ii += 1
          break unless ii < argv.size

          # Ruby ARGV is without command as first argument
          # Skipping the first argument.
          # next if ii == 0

          v = argv[ii]

          if v[0, 2] == '--'
            # This is a long-form option.
            option_name = v[2..-1]
            option_value = true
            if option_name.index('=')
              (option_name, option_value) = option_name.split('=')
            end
            options[option_name] = option_value
          elsif v[0] == '-' && v.length > 1
            # This is a short-form option.
            v[1..-1].chars.each do |option|
              options[option] = true
            end
          else
            positional << v
          end
        end

        [options, positional]
      end

      # RUBY: attr_accessor :parser

      # Reads the input file.
      #
      # @return [Component]
      def read_input
        unless @parser
          @stdin = File.open(@input_path, 'r') if @input_path != '-'

          if @input_format == 'mimedir'
            @parser = Parser::MimeDir.new(@stdin, (@forgiving ? Reader::OPTION_FORGIVING : 0))
          else
            @parser = Parser::Json.new(@stdin, (@forgiving ? Reader::OPTION_FORGIVING : 0))
          end
        end

        @parser.parse
      end

      # Sends a message to STDERR.
      #
      # @param [String] msg
      #
      # @return [void]
      def log(msg, color = 'default')
        return if @quiet

        msg = colorize(color, msg) unless color == 'default'
        @stderr.write(msg + "\n")
      end

      public

      def initialize
        @quiet = false
        @show_help = false
        @forgiving = false
      end
    end
  end
end
