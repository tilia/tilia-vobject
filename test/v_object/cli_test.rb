require 'test_helper'
require 'tempfile'
require 'v_object/cli_mock'
require 'stringio'

module Tilia
  module VObject
    # Tests the cli.
    #
    # Warning: these tests are very rudimentary.
    class CliTest < Minitest::Test
      def setup
        @cli = Tilia::VObject::CliMock.new
        @cli.stderr = StringIO.new
        @cli.stdout = StringIO.new
      end

      def test_invalid_arg
        assert_equal(1, @cli.main(['--hi']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)
      end

      def test_quiet
        assert_equal(1, @cli.main(['-q']))
        assert(@cli.quiet)

        @cli.stderr.rewind
        assert_equal(0, @cli.stderr.size)
      end

      def test_help
        assert_equal(0, @cli.main(['-h']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)
      end

      def test_format
        assert_equal(1, @cli.main(['--format=jcard']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)

        assert_equal('jcard', @cli.format)
      end

      def test_format_invalid
        assert_equal(1, @cli.main(['--format=foo']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)
        assert_nil(@cli.format)
      end

      def test_input_format_invalid
        assert_equal(1, @cli.main(['--inputformat=foo']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)
        assert_nil(@cli.format)
      end

      def test_no_input_file
        assert_equal(1, @cli.main(['color']))
        @cli.stderr.rewind
        assert(@cli.stderr.size > 100)
      end

      def test_too_many_args
        assert_equal(1, @cli.main(['color', 'a', 'b', 'c']))
      end

      def test_unknown_command
        assert_equal(1, @cli.main(['foo', '-']))
      end

      def test_convert_json
        input_stream = StringIO.new

        input_stream.write(
          <<ICS
BEGIN:VCARD
VERSION:3.0
FN:Cowboy Henk
END:VCARD
ICS
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(0, @cli.main(['convert', '--format=json', '-']))

        @cli.stdout.rewind
        version = Tilia::VObject::Version::VERSION
        assert_equal(
          '["vcard",[["version",{},"text","4.0"],["prodid",{},"text","-//Tilia//Tilia VObject ' + version + '//EN"],["fn",{},"text","Cowboy Henk"]]]',
          @cli.stdout.readlines.join('')
        )
      end

      def test_convert_j_card_pretty
        input_stream = StringIO.new

        input_stream.write(
          <<ICS
BEGIN:VCARD
VERSION:3.0
FN:Cowboy Henk
END:VCARD
ICS
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(0, @cli.main(['convert', '--format=jcard', '--pretty', '-']))

        @cli.stdout.rewind

        expected = <<JCARD
[
  "vcard",
  [
    [
      "version",
JCARD

        assert_equal(expected, @cli.stdout.readlines.join('')[0..39])
      end

      def test_convert_j_cal_fail
        input_stream = StringIO.new

        input_stream.write(
          <<ICS
BEGIN:VCARD
VERSION:3.0
FN:Cowboy Henk
END:VCARD
ICS
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(2, @cli.main(['convert', '--format=jcal', '--inputformat=mimedir', '-']))
      end

      def test_convert_mime_dir
        input_stream = StringIO.new

        input_stream.write(
          <<JCARD
[
  "vcard",
  [
      [
          "version",
          {

          },
          "text",
          "4.0"
      ],
      [
          "prodid",
          {

          },
          "text",
          "-//Tilia//Tilia VObject 3.1.0//EN"
      ],
      [
          "fn",
          {

          },
          "text",
          "Cowboy Henk"
      ]
  ]
]
JCARD
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(0, @cli.main(['convert', '--format=mimedir', '--inputformat=json', '--pretty', '-']))

        @cli.stdout.rewind
        expected = <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
FN:Cowboy Henk
END:VCARD
VCF

        assert_equal(expected, @cli.stdout.readlines.join('').gsub("\r\n", "\n"))
      end

      def test_convert_default_formats
        output_file = File.join(Dir.tmpdir, 'bar.json')

        assert_equal(2, @cli.main(['convert', 'foo.json', output_file]))

        assert_equal('json', @cli.input_format)
        assert_equal('json', @cli.format)
      end

      def test_convert_default_formats2
        output_file = File.join(Dir.tmpdir, 'bar.ics')

        assert_equal(2, @cli.main(['convert', 'foo.ics', output_file]))
        assert_equal('mimedir', @cli.input_format)
        assert_equal('mimedir', @cli.format)
      end

      def test_v_card3040
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:3.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
FN:Cowboy Henk
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(0, @cli.main(['convert', '--format=vcard40', '--pretty', '-']))

        @cli.stdout.rewind

        version = Tilia::VObject::Version::VERSION
        expected = <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
FN:Cowboy Henk
END:VCARD
VCF

        assert_equal(expected, @cli.stdout.readlines.join('').gsub("\r\n", "\n"))
      end

      def test_v_card4030
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
FN:Cowboy Henk
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(0, @cli.main(['convert', '--format=vcard30', '--pretty', '-']))

        version = Tilia::VObject::Version::VERSION

        @cli.stdout.rewind
        expected = <<VCF
BEGIN:VCARD
VERSION:3.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
FN:Cowboy Henk
END:VCARD
VCF

        assert_equal(expected, @cli.stdout.readlines.join('').gsub("\r\n", "\n"))
      end

      def test_v_card4021
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
FN:Cowboy Henk
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        assert_equal(2, @cli.main(['convert', '--format=vcard21', '--pretty', '-']))
      end

      def test_validate
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
UID:foo
FN:Cowboy Henk
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream
        result = @cli.main(['validate', '-'])

        assert_equal(0, result)
      end

      def test_validate_fail
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCALENDAR
VERSION:2.0
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream
        # vCard 2.0 is not supported yet, so this returns a failure.
        assert_equal(2, @cli.main(['validate', '-']))
      end

      def test_validate_fail2
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCALENDAR
VERSION:5.0
END:VCALENDAR
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream
        assert_equal(2, @cli.main(['validate', '-']))
      end

      def test_repair
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:5.0
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream
        assert_equal(2, @cli.main(['repair', '-']))

        @cli.stdout.rewind
        assert(@cli.stdout.readlines.join('') =~ /BEGIN:VCARD\r\nVERSION:2.1\r\nUID:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\r\nEND:VCARD\r\n$/)
      end

      def test_repair_nothing
        input_stream = StringIO.new

        input_stream.write(
          <<VCF
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject 3.1.0//EN
BEGIN:VEVENT
UID:foo
DTSTAMP:20140122T233226Z
DTSTART:20140101T120000Z
END:VEVENT
END:VCALENDAR
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        result = @cli.main(['repair', '-'])

        @cli.stderr.rewind
        error = @cli.stderr.readlines.join('')

        assert_equal(0, result, "This should have been error free. stderr output:\n#{error}")
      end

      # Note: this is a very shallow test, doesn't dig into the actual output,
      # but just makes sure there's no errors thrown.
      #
      # The colorizer is not a critical component, it's mostly a debugging tool.
      def test_color_calendar
        input_stream = StringIO.new

        version = Tilia::VObject::Version::VERSION

        # This object is not valid, but it's designed to hit every part of the
        # colorizer source.
        input_stream.write(
          <<VCF
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
BEGIN:VTIMEZONE
END:VTIMEZONE
BEGIN:VEVENT
ATTENDEE;RSVP=TRUE:mailto:foo@example.org
REQUEST-STATUS:5;foo
ATTACH:blabla
END:VEVENT
END:VCALENDAR
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        result = @cli.main(['color', '-'])

        @cli.stderr.rewind
        error = @cli.stderr.readlines.join('')

        assert_equal(0, result, "This should have been error free. stderr output:\n#{error}")
      end

      # Note: this is a very shallow test, doesn't dig into the actual output,
      # but just makes sure there's no errors thrown.
      #
      # The colorizer is not a critical component, it's mostly a debugging tool.
      def test_color_v_card
        input_stream = StringIO.new

        version = Tilia::VObject::Version::VERSION

        # This object is not valid, but it's designed to hit every part of the
        # colorizer source.
        input_stream.write(
          <<VCF
BEGIN:VCARD
VERSION:4.0
PRODID:-//Tilia//Tilia VObject #{version}//EN
ADR:1;2;3;4a,4b;5;6
group.TEL:123454768
END:VCARD
VCF
        )
        input_stream.rewind
        @cli.stdin = input_stream

        result = @cli.main(['color', '-'])

        @cli.stderr.rewind
        error = @cli.stderr.readlines.join('')

        assert_equal(0, result, "This should have been error free. stderr output:\n#{error}")
      end
    end
  end
end
