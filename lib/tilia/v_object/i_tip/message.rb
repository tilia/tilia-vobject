module Tilia
  module VObject
    module ITip
      # This class represents an iTip message.
      #
      # A message holds all the information relevant to the message, including the
      # object itself.
      #
      # It should for the most part be treated as immutable.
      class Message
        # The object's UID.
        #
        # @return [String]
        attr_accessor :uid

        # The component type, such as VEVENT.
        #
        # @return [String]
        attr_accessor :component

        # Contains the ITip method, which is something like REQUEST, REPLY or
        # CANCEL.
        #
        # @return [String]
        attr_accessor :method

        # The current sequence number for the event.
        #
        # @return [Fixnum]
        attr_accessor :sequence

        # The senders' email address.
        #
        # Note that this does not imply that this has to be used in a From: field
        # if the message is sent by email. It may also be populated in Reply-To:
        # or not at all.
        #
        # @return [String]
        attr_accessor :sender

        # The name of the sender. This is often populated from a CN parameter from
        # either the ORGANIZER or ATTENDEE, depending on the message.
        #
        # @return [String, nil]
        attr_accessor :sender_name

        # The recipient's email address.
        #
        # @return [String]
        attr_accessor :recipient

        # The name of the recipient. This is usually populated with the CN
        # parameter from the ATTENDEE or ORGANIZER property, if it's available.
        #
        # @return [String, nil]
        attr_accessor :recipient_name

        # After the message has been delivered, this should contain a string such
        # as : 1.1;Sent or 1.2;Delivered.
        #
        # In case of a failure, this will hold the error status code.
        #
        # See:
        # http://tools.ietf.org/html/rfc6638#section-7.3
        #
        # @return [String]
        attr_accessor :schedule_status

        # The iCalendar / iTip body.
        #
        # @return [Component::VCalendar]
        attr_accessor :message

        # This will be set to true, if the iTip broker considers the change
        # 'significant'.
        #
        # In practice, this means that we'll only mark it true, if for instance
        # DTSTART changed. This allows systems to only send iTip messages when
        # significant changes happened. This is especially useful for iMip, as
        # normally a ton of messages may be generated for normal calendar use.
        #
        # To see the list of properties that are considered 'significant', check
        # out Sabre\VObject\ITip\Broker::significant_change_properties.
        #
        # @return [Boolean]
        attr_accessor :significant_change

        # Returns the schedule status as a string.
        #
        # For example:
        # 1.2
        #
        # @return [String, false]
        def schedule_status
          if !@schedule_status
            false
          else
            @schedule_status.split(';').first
          end
        end

        # Initialize instance variables
        def initialize
          @significant_change = true
        end
      end
    end
  end
end
