require 'simplecov'
require 'minitest/autorun'

# # Extend the matchers
# require 'rspec/expectations'
# RSpec::Matchers.define :vobject_eq do |expected|
#
#   # This method tests wether two vcards or icalendar objects are
#   # semantically identical.
#   #
#   # It supports objects being supplied as strings, streams or
#   # Sabre\VObject\Component instances.
#   #
#   # PRODID is removed from both objects as this is often changes and would
#   # just get in the way.
#   #
#   # CALSCALE will automatically get removed if it's set to GREGORIAN.
#   #
#   # @param resource|string|Component expected
#   # @param resource|string|Component actual
#   # @param string message
#   self.obj = lambda do |input|
#     if input.respond_to?(:readlines)
#       input = input.readlines.join("\n")
#     end
#
#     if input.is_a?(String)
#       input = Tilia::VObject::Reader.read(input)
#     end
#
#     unless input.is_a?(Tilia::VObject::Component)
#       fail ArgumentError, 'Input must be a string, stream or VObject component'
#     end
#
#     input.delete('PRODID')
#     if input.is_a?(Tilia::VObject::Component::VCalendar) && input['CALSCALE'].to_s == 'GREGORIAN'
#       input.delete('CALSCALE')
#     end
#     input
#   end
#
#   expected = self.obj.call(expected)
#   match do |actual|
#     actual = self.obj.call(actual)
#     actual.serialize == expected.serialize
#   end
#
#   failure_message do |actual|
#     ">>> expected:\n#{expected.serialize}\n<<<\n>>> got:\n#{actual.serialize}\n<<<"
#   end
# end

# require our lib
require 'tilia/vobject'

Time.zone = 'UTC'
