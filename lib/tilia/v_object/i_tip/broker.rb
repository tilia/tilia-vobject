require 'digest'
module Tilia
  module VObject
    module ITip
      # The ITip\Broker class is a utility class that helps with processing
      # so-called iTip messages.
      #
      # iTip is defined in rfc5546, stands for iCalendar Transport-Independent
      # Interoperability Protocol, and describes the underlying mechanism for
      # using iCalendar for scheduling for for example through email (also known as
      # IMip) and CalDAV Scheduling.
      #
      # This class helps by:
      #
      # 1. Creating individual invites based on an iCalendar event for each
      #    attendee.
      # 2. Generating invite updates based on an iCalendar update. This may result
      #    in new invites, updates and cancellations for attendees, if that list
      #    changed.
      # 3. On the receiving end, it can create a local iCalendar event based on
      #    a received invite.
      # 4. It can also process an invite update on a local event, ensuring that any
      #    overridden properties from attendees are retained.
      # 5. It can create a accepted or declined iTip reply based on an invite.
      # 6. It can process a reply from an invite and update an events attendee
      #     status based on a reply.
      class Broker
        # This setting determines whether the rules for the SCHEDULE-AGENT
        # parameter should be followed.
        #
        # This is a parameter defined on ATTENDEE properties, introduced by RFC
        # 6638. This parameter allows a caldav client to tell the server 'Don't do
        # any scheduling operations'.
        #
        # If this setting is turned on, any attendees with SCHEDULE-AGENT set to
        # CLIENT will be ignored. This is the desired behavior for a CalDAV
        # server, but if you're writing an iTip application that doesn't deal with
        # CalDAV, you may want to ignore this parameter.
        #
        # @var bool
        attr_accessor :schedule_agent_server_rules

        # The broker will try during 'parseEvent' figure out whether the change
        # was significant.
        #
        # It uses a few different ways to do this. One of these ways is seeing if
        # certain properties changed values. This list of specified here.
        #
        # This list is taken from:
        # * http://tools.ietf.org/html/rfc5546#section-2.1.4
        #
        # @var string[]
        attr_accessor :significant_change_properties

        # This method is used to process an incoming itip message.
        #
        # Examples:
        #
        # 1. A user is an attendee to an event. The organizer sends an updated
        # meeting using a new iTip message with METHOD:REQUEST. This function
        # will process the message and update the attendee's event accordingly.
        #
        # 2. The organizer cancelled the event using METHOD:CANCEL. We will update
        # the users event to state STATUS:CANCELLED.
        #
        # 3. An attendee sent a reply to an invite using METHOD:REPLY. We can
        # update the organizers event to update the ATTENDEE with its correct
        # PARTSTAT.
        #
        # The existing_object is updated in-place. If there is no existing object
        # (because it's a new invite for example) a new object will be created.
        #
        # If an existing object does not exist, and the method was CANCEL or
        # REPLY, the message effectively gets ignored, and no 'existingObject'
        # will be created.
        #
        # The updated existing_object is also returned from this function.
        #
        # If the iTip message was not supported, we will always return false.
        #
        # @param Message itip_message
        # @param VCalendar existing_object
        #
        # @return VCalendar|null
        def process_message(itip_message, existing_object = nil)
          # We only support events at the moment.
          return false unless itip_message.component == 'VEVENT'

          case itip_message.method
          when 'REQUEST'
            process_message_request(itip_message, existing_object)
          when 'CANCEL'
            process_message_cancel(itip_message, existing_object)
          when 'REPLY'
            process_message_reply(itip_message, existing_object)
          end
        end

        # This function parses a VCALENDAR object and figure out if any messages
        # need to be sent.
        #
        # A VCALENDAR object will be created from the perspective of either an
        # attendee, or an organizer. You must pass a string identifying the
        # current user, so we can figure out who in the list of attendees or the
        # organizer we are sending this message on behalf of.
        #
        # It's possible to specify the current user as an array, in case the user
        # has more than one identifying href (such as multiple emails).
        #
        # It old_calendar is specified, it is assumed that the operation is
        # updating an existing event, which means that we need to look at the
        # differences between events, and potentially send old attendees
        # cancellations, and current attendees updates.
        #
        # If calendar is null, but old_calendar is specified, we treat the
        # operation as if the user has deleted an event. If the user was an
        # organizer, this means that we need to send cancellation notices to
        # people. If the user was an attendee, we need to make sure that the
        # organizer gets the 'declined' message.
        #
        # @param VCalendar|string calendar
        # @param string|array user_href
        # @param VCalendar|string old_calendar
        #
        # @return array
        def parse_event(calendar, user_href, old_calendar = nil)
          if old_calendar
            if old_calendar.is_a?(String)
              old_calendar = Tilia::VObject::Reader.read(old_calendar)
            end
            unless old_calendar.key?('VEVENT')
              # We only support events at the moment
              return []
            end

            old_event_info = parse_event_info(old_calendar)
          else
            old_event_info = {
              'organizer'             => nil,
              'significant_change_hash' => '',
              'attendees'             => {}
            }
          end

          user_href = [user_href] unless user_href.is_a?(Array)

          if calendar
            if calendar.is_a?(String)
              calendar = Tilia::VObject::Reader.read(calendar)
            end

            unless calendar.key?('VEVENT')
              # We only support events at the moment
              return []
            end

            event_info = parse_event_info(calendar)
            if (!event_info['attendees'] || event_info['attendees'].empty?) &&
               (!old_event_info['attendees'] || old_event_info['attendees'].empty?)
              # If there were no attendees on either side of the equation,
              # we don't need to do anything.
              return []
            end

            if event_info['organizer'].blank? && old_event_info['organizer'].blank?
              # There was no organizer before or after the change.
              return []
            end

            base_calendar = calendar

            # If the new object didn't have an organizer, the organizer
            # changed the object from a scheduling object to a non-scheduling
            # object. We just copy the info from the old object.
            if event_info['organizer'].blank? && !old_event_info['organizer'].blank?
              event_info['organizer'] = old_event_info['organizer']
              event_info['organizer_name'] = old_event_info['organizer_name']
            end
          else
            # The calendar object got deleted, we need to process this as a
            # cancellation / decline.
            unless old_calendar
              # No old and no new calendar, there's no thing to do.
              return []
            end

            event_info = old_event_info.deep_dup

            if user_href.include?(event_info['organizer'])
              # This is an organizer deleting the event.
              event_info['attendees'] = {}

              # Increasing the sequence, but only if the organizer deleted
              # the event.
              event_info['sequence'] += 1
            else
              # This is an attendee deleting the event.
              event_info['attendees'].each do |key, attendee|
                if user_href.include?(attendee['href'])
                  event_info['attendees'][key]['instances'] = {
                    'master' => { 'id' => 'master', 'partstat' => 'DECLINED' }
                  }
                end
              end
            end

            base_calendar = old_calendar
          end

          if user_href.include?(event_info['organizer'])
            return parse_event_for_organizer(base_calendar, event_info, old_event_info)
          elsif old_calendar
            # We need to figure out if the user is an attendee, but we're only
            # doing so if there's an oldCalendar, because we only want to
            # process updates, not creation of new events.
            event_info['attendees'].each do |_, attendee|
              if user_href.include?(attendee['href'])
                return parse_event_for_attendee(base_calendar, event_info, old_event_info, attendee['href'])
              end
            end
          end

          return []
        end

        protected

        # Processes incoming REQUEST messages.
        #
        # This is message from an organizer, and is either a new event
        # invite, or an update to an existing one.
        #
        #
        # @param Message itip_message
        # @param VCalendar existing_object
        #
        # @return VCalendar|null
        def process_message_request(itip_message, existing_object = nil)
          if !existing_object
            # This is a new invite, and we're just going to copy over
            # all the components from the invite.
            existing_object = Tilia::VObject::Component::VCalendar.new
            itip_message.message.components.each do |component|
              existing_object.add(component.clone)
            end
          else
            # We need to update an existing object with all the new
            # information. We can just remove all existing components
            # and create new ones.
            existing_object.components.each do |component|
              existing_object.remove(component)
            end
            itip_message.message.components.each do |component|
              existing_object.add(component.clone)
            end
          end

          existing_object
        end

        # Processes incoming CANCEL messages.
        #
        # This is a message from an organizer, and means that either an
        # attendee got removed from an event, or an event got cancelled
        # altogether.
        #
        # @param Message itip_message
        # @param VCalendar existing_object
        #
        # @return VCalendar|null
        def process_message_cancel(itip_message, existing_object = nil)
          if !existing_object
            # The event didn't exist in the first place, so we're just
            # ignoring this message.
          else
            existing_object['VEVENT'].each do |vevent|
              vevent['STATUS'] = 'CANCELLED'
              vevent['SEQUENCE'] = itip_message.sequence
            end
          end

          existing_object
        end

        # Processes incoming REPLY messages.
        #
        # The message is a reply. This is for example an attendee telling
        # an organizer he accepted the invite, or declined it.
        #
        # @param Message itip_message
        # @param VCalendar existing_object
        #
        # @return VCalendar|null
        def process_message_reply(itip_message, existing_object = nil)
          # A reply can only be processed based on an existing object.
          # If the object is not available, the reply is ignored.
          return nil unless existing_object

          instances = {}
          request_status = '2.0'

          # Finding all the instances the attendee replied to.
          itip_message.message['VEVENT'].each do |vevent|
            recur_id = vevent.key?('RECURRENCE-ID') ? vevent['RECURRENCE-ID'].value : 'master'
            attendee = vevent['ATTENDEE']
            instances[recur_id] = attendee['PARTSTAT'].value
            if vevent.key?('REQUEST-STATUS')
              request_status = vevent['REQUEST-STATUS'].value
              request_status = request_status.split(';').first
            end
          end

          # Now we need to loop through the original organizer event, to find
          # all the instances where we have a reply for.
          master_object = nil
          existing_object['VEVENT'].each do |vevent|
            recur_id = vevent.key?('RECURRENCE-ID') ? vevent['RECURRENCE-ID'].value : 'master'
            master_object = vevent if recur_id == 'master'

            if instances.key?(recur_id)
              attendee_found = false
              if vevent.key?('ATTENDEE')
                vevent['ATTENDEE'].each do |attendee|
                  if attendee.value == itip_message.sender
                    attendee_found = true
                    attendee['PARTSTAT'] = instances[recur_id]
                    attendee['SCHEDULE-STATUS'] = request_status
                    # Un-setting the RSVP status, because we now know
                    # that the attendee already replied.
                    attendee.delete('RSVP')
                    break
                  end
                end
              end

              unless attendee_found
                # Adding a new attendee. The iTip documentation calls this
                # a party crasher.
                attendee = vevent.add('ATTENDEE', itip_message.sender, 'PARTSTAT' => instances[recur_id])
                if itip_message.sender_name
                  attendee['CN'] = itip_message.sender_name
                end
              end

              instances.delete(recur_id)
            end
          end

          unless master_object
            # No master object, we can't add new instances.
            return nil
          end

          # If we got replies to instances that did not exist in the
          # original list, it means that new exceptions must be created.
          instances.each do |recur_id, partstat|
            recurrence_iterator = Tilia::VObject::Recur::EventIterator.new(existing_object, itip_message.uid)
            found = false
            iterations = 1000

            new_object = nil
            loop do
              new_object = recurrence_iterator.event_object
              recurrence_iterator.next

              if new_object.key?('RECURRENCE-ID') && new_object['RECURRENCE-ID'].value == recur_id
                found = true
              end
              iterations -= 1
              break unless recurrence_iterator.valid && !found && iterations > 0
            end

            # Invalid recurrence id. Skipping this object.
            next unless found

            new_object.delete('RRULE')
            new_object.delete('EXDATE')
            new_object.delete('RDATE')

            attendee_found = false
            if new_object.key?('ATTENDEE')
              new_object['ATTENDEE'].each do |attendee|
                if attendee.value == itip_message.sender
                  attendee_found = true
                  attendee['PARTSTAT'] = partstat
                  break
                end
              end
            end

            unless attendee_found
              # Adding a new attendee
              attendee = new_object.add('ATTENDEE', itip_message.sender, 'PARTSTAT' => partstat )

              if itip_message.sender_name
                attendee['CN'] = itip_message.sender_name
              end
            end

            existing_object.add(new_object)
          end

          existing_object
        end

        # This method is used in cases where an event got updated, and we
        # potentially need to send emails to attendees to let them know of updates
        # in the events.
        #
        # We will detect which attendees got added, which got removed and create
        # specific messages for these situations.
        #
        # @param VCalendar calendar
        # @param array event_info
        # @param array old_event_info
        #
        # @return array
        def parse_event_for_organizer(calendar, event_info, old_event_info)
          # Merging attendee lists.
          attendees = {}
          old_event_info['attendees'].each do |_, attendee|
            attendees[attendee['href']] = {
              'href'         => attendee['href'],
              'oldInstances' => attendee['instances'],
              'newInstances' => {},
              'name'         => attendee['name'],
              'forceSend'    => nil
            }
          end
          event_info['attendees'].each do |_, attendee|
            if attendees.key?(attendee['href'])
              attendees[attendee['href']]['name'] = attendee['name']
              attendees[attendee['href']]['newInstances'] = attendee['instances']
              attendees[attendee['href']]['forceSend'] = attendee['forceSend']
            else
              attendees[attendee['href']] = {
                'href'         => attendee['href'],
                'oldInstances' => {},
                'newInstances' => attendee['instances'],
                'name'         => attendee['name'],
                'forceSend'    => attendee['forceSend']
              }
            end
          end

          messages = []

          attendees.each do |_, attendee|
            # An organizer can also be an attendee. We should not generate any
            # messages for those.
            next if attendee['href'] == event_info['organizer']

            message = Tilia::VObject::ITip::Message.new
            message.uid = event_info['uid']
            message.component = 'VEVENT'
            message.sequence = event_info['sequence']
            message.sender = event_info['organizer']
            message.sender_name = event_info['organizer_name']
            message.recipient = attendee['href']
            message.recipient_name = attendee['name']

            if attendee['newInstances'].empty?
              # If there are no instances the attendee is a part of, it
              # means the attendee was removed and we need to send him a
              # CANCEL.
              message.method = 'CANCEL'

              # Creating the new iCalendar body.
              ical_msg = Tilia::VObject::Component::VCalendar.new
              ical_msg['METHOD'] = message.method
              event = ical_msg.add(
                'VEVENT',
                'UID'      => message.uid,
                'SEQUENCE' => message.sequence
              )
              if calendar['VEVENT'].key?('SUMMARY')
                event.add('SUMMARY', calendar['VEVENT']['SUMMARY'].value)
              end

              event.add(calendar['VEVENT']['DTSTART'].clone)
              org = event.add('ORGANIZER', event_info['organizer'])
              if event_info['organizer_name']
                org['CN'] = event_info['organizer_name']
              end
              event.add(
                'ATTENDEE',
                attendee['href'],
                'CN' => attendee['name']
              )
              message.significant_change = true
            else
              # The attendee gets the updated event body
              message.method = 'REQUEST'

              # Creating the new iCalendar body.
              ical_msg = Tilia::VObject::Component::VCalendar.new
              ical_msg['METHOD'] = message.method

              calendar.select('VTIMEZONE').each do |timezone|
                ical_msg.add(timezone.clone)
              end

              # We need to find out that this change is significant. If it's
              # not, systems may opt to not send messages.
              #
              # We do this based on the 'significantChangeHash' which is
              # some value that changes if there's a certain set of
              # properties changed in the event, or simply if there's a
              # difference in instances that the attendee is invited to.

              message.significant_change =
                attendee['forceSend'] == 'REQUEST' ||
                attendee['oldInstances'].values != attendee['newInstances'].values ||
                old_event_info['significant_change_hash'] != event_info['significant_change_hash']

              attendee['newInstances'].each do |instance_id, _instance_info|
                current_event = event_info['instances'][instance_id].clone
                if instance_id == 'master'
                  # We need to find a list of events that the attendee
                  # is not a part of to add to the list of exceptions.
                  exceptions = []
                  event_info['instances'].each do |instance_id, _vevent|
                    unless attendee['newInstances'].key?(instance_id)
                      exceptions << instance_id
                    end
                  end

                  # If there were exceptions, we need to add it to an
                  # existing EXDATE property, if it exists.
                  if exceptions.any?
                    if current_event.key?('EXDATE')
                      current_event['EXDATE'].parts = current_event['EXDATE'].parts + exceptions
                    else
                      current_event['EXDATE'] = exceptions
                    end
                  end

                  # Cleaning up any scheduling information that
                  # shouldn't be sent along.
                  current_event['ORGANIZER'].delete('SCHEDULE-FORCE-SEND')
                  current_event['ORGANIZER'].delete('SCHEDULE-STATUS')

                  current_event['ATTENDEE'].each do |attendee|
                    attendee.delete('SCHEDULE-FORCE-SEND')
                    attendee.delete('SCHEDULE-STATUS')

                    # We're adding PARTSTAT=NEEDS-ACTION to ensure that
                    # iOS shows an "Inbox Item"
                    unless attendee.key?('PARTSTAT')
                      attendee['PARTSTAT'] = 'NEEDS-ACTION'
                    end
                  end
                end

                ical_msg.add(current_event)
              end
            end

            message.message = ical_msg
            messages << message
          end

          return messages
        end

        # Parse an event update for an attendee.
        #
        # This function figures out if we need to send a reply to an organizer.
        #
        # @param VCalendar calendar
        # @param array event_info
        # @param array old_event_info
        # @param string attendee
        #
        # @return Message[]
        def parse_event_for_attendee(calendar, event_info, old_event_info, attendee)
          if schedule_agent_server_rules && event_info['organizer_schedule_agent'] == 'CLIENT'
            return []
          end

          # Don't bother generating messages for events that have already been
          # cancelled.
          return [] if event_info['status'] == 'CANCELLED'

          if old_event_info['attendees'].key?(attendee)
            old_instances = old_event_info['attendees'][attendee]['instances'] || {}
          else
            old_instances = {}
          end

          instances = {}
          old_instances.each do |_, instance|
            instances[instance['id']] = {
              'id'        => instance['id'],
              'oldstatus' => instance['partstat'],
              'newstatus' => nil
            }
          end

          event_info['attendees'][attendee]['instances'].each do |_, instance|
            if instances.key?(instance['id'])
              instances[instance['id']]['newstatus'] = instance['partstat']
            else
              instances[instance['id']] = {
                'id'        => instance['id'],
                'oldstatus' => nil,
                'newstatus' => instance['partstat']
              }
            end
          end

          # We need to also look for differences in EXDATE. If there are new
          # items in EXDATE, it means that an attendee deleted instances of an
          # event, which means we need to send DECLINED specifically for those
          # instances.
          # We only need to do that though, if the master event is not declined.
          if instances.key?('master') && instances['master']['newstatus'] != 'DECLINED'
            event_info['exdate'].each do |ex_date|
              unless old_event_info['exdate'].include?(ex_date)
                if instances.key?(ex_date)
                  instances[ex_date]['newstatus'] = 'DECLINED'
                else
                  instances[ex_date] = {
                    'id'        => ex_date,
                    'oldstatus' => nil,
                    'newstatus' => 'DECLINED'
                  }
                end
              end
            end
          end

          # Gathering a few extra properties for each instance.
          instances.each do |recur_id, _instance_info|
            if event_info['instances'].key?(recur_id)
              instances[recur_id]['dtstart'] = event_info['instances'][recur_id]['DTSTART'].clone
            else
              instances[recur_id]['dtstart'] = recur_id
            end
          end

          message = Tilia::VObject::ITip::Message.new
          message.uid = event_info['uid']
          message.method = 'REPLY'
          message.component = 'VEVENT'
          message.sequence = event_info['sequence']
          message.sender = attendee
          message.sender_name = event_info['attendees'][attendee]['name']
          message.recipient = event_info['organizer']
          message.recipient_name = event_info['organizer_name']

          ical_msg = Tilia::VObject::Component::VCalendar.new
          ical_msg['METHOD'] = 'REPLY'

          has_reply = false

          instances.each do |_, instance|
            if instance['oldstatus'] == instance['newstatus'] && event_info['organizer_force_send'] != 'REPLY'
              # Skip
              next
            end

            event = ical_msg.add(
              'VEVENT',
              'UID'      => message.uid,
              'SEQUENCE' => message.sequence
            )

            summary = calendar['VEVENT'].key?('SUMMARY') ? calendar['VEVENT']['SUMMARY'].value : ''
            # Adding properties from the correct source instance
            if event_info['instances'].key?(instance['id'])
              instance_obj = event_info['instances'][instance['id']]

              event.add(instance_obj['DTSTART'].clone)
              if instance_obj.key?('SUMMARY')
                event.add('SUMMARY', instance_obj['SUMMARY'].value)
              elsif !summary.blank?
                event.add('SUMMARY', summary)
              end
            else
              # This branch of the code is reached, when a reply is
              # generated for an instance of a recurring event, through the
              # fact that the instance has disappeared by showing up in
              # EXDATE
              dt = Tilia::VObject::DateTimeParser.parse(instance['id'], event_info['timezone'])

              # Treat is as a DATE field
              if instance['id'].size <= 8
                recur = event.add('DTSTART', dt, 'VALUE' => 'DATE')
              else
                recur = event.add('DTSTART', dt)
              end

              event.add('SUMMARY', summary) unless summary.blank?
            end

            if instance['id'] != 'master'
              dt = Tilia::VObject::DateTimeParser.parse(instance['id'], event_info['timezone'])
              # Treat is as a DATE field
              if instance['id'].size <= 8
                recur = event.add('RECURRENCE-ID', dt, 'VALUE' => 'DATE')
              else
                recur = event.add('RECURRENCE-ID', dt)
              end
            end

            organizer = event.add('ORGANIZER', message.recipient)
            organizer['CN'] = message.recipient_name if message.recipient_name

            attendee = event.add(
              'ATTENDEE',
              message.sender,
              'PARTSTAT' => instance['newstatus']
            )
            attendee['CN'] = message.sender_name if message.sender_name

            has_reply = true
          end

          if has_reply
            message.message = ical_msg
            [message]
          else
            []
          end
        end

        # Returns attendee information and information about instances of an
        # event.
        #
        # Returns an array with the following keys:
        #
        # 1. uid
        # 2. organizer
        # 3. organizer_name
        # 4. attendees
        # 5. instances
        #
        # @param VCalendar calendar
        #
        # @return array
        def parse_event_info(calendar = nil)
          uid = nil
          organizer = nil
          organizer_name = nil
          organizer_force_send = nil
          sequence = nil
          timezone = nil
          status = nil
          organizer_schedule_agent = 'SERVER'

          significant_change_hash = ''

          # Now we need to collect a list of attendees, and which instances they
          # are a part of.
          attendees = {}

          instances = {}
          exdate = []

          calendar['VEVENT'].each do |vevent|
            if uid.nil?
              uid = vevent['UID'].value
            else
              if uid != vevent['UID'].value
                fail Tilia::VObject::ITip::ITipException, 'If a calendar contained more than one event, they must have the same UID.'
              end
            end

            unless vevent.key?('DTSTART')
              fail Tilia::VObject::ITip::ITipException, 'An event MUST have a DTSTART property.'
            end

            if vevent.key?('ORGANIZER')
              if organizer.nil?
                organizer = vevent['ORGANIZER'].normalized_value
                organizer_name = vevent['ORGANIZER'].key?('CN') ? vevent['ORGANIZER']['CN'] : nil
              else
                if organizer != vevent['ORGANIZER'].normalized_value
                  fail Tilia::VObject::ITip::SameOrganizerForAllComponentsException, 'Every instance of the event must have the same organizer.'
                end
              end
              organizer_force_send =
                  vevent['ORGANIZER'].key?('SCHEDULE-FORCE-SEND') ?
                  vevent['ORGANIZER']['SCHEDULE-FORCE-SEND'].to_s.upcase :
                  nil
              organizer_schedule_agent =
                  vevent['ORGANIZER'].key?('SCHEDULE-AGENT') ?
                  vevent['ORGANIZER']['SCHEDULE-AGENT'].to_s.upcase :
                  'SERVER'
            end

            if sequence.nil? && vevent.key?('SEQUENCE')
              sequence = vevent['SEQUENCE'].value
            end

            if vevent.key?('EXDATE')
              vevent.select('EXDATE').each do |val|
                exdate = exdate + val.parts
              end
              exdate.sort!
            end

            status = vevent['STATUS'].value.upcase if vevent.key?('STATUS')

            recur_id = vevent.key?('RECURRENCE-ID') ? vevent['RECURRENCE-ID'].value : 'master'
            if recur_id == 'master'
              timezone = vevent['DTSTART'].date_time.time_zone
            end

            if vevent.key?('ATTENDEE')
              vevent['ATTENDEE'].each do |attendee|
                if schedule_agent_server_rules &&
                   attendee.key?('SCHEDULE-AGENT') &&
                   attendee['SCHEDULE-AGENT'].value.upcase == 'CLIENT'
                  next
                end

                part_stat =
                    attendee.key?('PARTSTAT') ?
                    attendee['PARTSTAT'].to_s.upcase :
                    'NEEDS-ACTION'

                force_send =
                    attendee.key?('SCHEDULE-FORCE-SEND') ?
                    attendee['SCHEDULE-FORCE-SEND'].to_s.upcase :
                    nil

                if attendees.key?(attendee.normalized_value)
                  attendees[attendee.normalized_value]['instances'][recur_id] = {
                    'id'         => recur_id,
                    'partstat'   => part_stat,
                    'force-send' => force_send
                  }
                else
                  attendees[attendee.normalized_value] = {
                    'href'      => attendee.normalized_value,
                    'instances' => {
                      recur_id => {
                        'id'       => recur_id,
                        'partstat' => part_stat
                      }
                    },
                    'name'      => attendee.key?('CN') ? attendee['CN'].to_s : nil,
                    'forceSend' => force_send
                  }
                end
              end

              instances[recur_id] = vevent
            end

            significant_change_properties.each do |prop|
              if vevent.key?(prop)
                property_values = vevent.select(prop)

                significant_change_hash += prop + ':'

                if prop == 'EXDATE'
                  significant_change_hash += exdate.join(',') + ';'
                else
                  property_values.each do |val|
                    significant_change_hash += val.value + ';'
                  end
                end
              end
            end
          end

          significant_change_hash = Digest::MD5.hexdigest(significant_change_hash)

          to_return = {}

          to_return['uid'] = uid if uid
          to_return['organizer'] = organizer if organizer
          to_return['organizer_name'] = organizer_name if organizer_name
          to_return['organizer_schedule_agent'] = organizer_schedule_agent if organizer_schedule_agent
          to_return['organizer_force_send'] = organizer_force_send if organizer_force_send
          to_return['instances'] = instances if instances
          to_return['attendees'] = attendees if attendees
          to_return['sequence'] = sequence if sequence
          to_return['exdate'] = exdate if exdate
          to_return['timezone'] = timezone if timezone
          to_return['significant_change_hash'] = significant_change_hash if significant_change_hash
          to_return['status'] = status if status

          to_return
        end

        public

        # TODO: document
        def initialize
          @schedule_agent_server_rules = true
          @significant_change_properties = [
            'DTSTART',
            'DTEND',
            'DURATION',
            'DUE',
            'RRULE',
            'RDATE',
            'EXDATE',
            'STATUS'
          ]
        end
      end
    end
  end
end
