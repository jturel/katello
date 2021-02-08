module Katello
  module EventMonitor
    # TODO: Move this class to app/lib/katello/event_daemon/services with other service definitions
    class PollerThread
      SLEEP_INTERVAL = 2

      def self.blocking
        true
      end

      def initialize
        @failed_count = 0
        @processed_count = 0
      end

      def run
        @running = true
        Rails.application.executor.wrap do
          ::Katello::EventQueue.reset_in_progress
          poll_for_events
        end
      ensure
        @running = false
      end

      def running?
        @running == true
      end

      def close
        @close = true
      end

      def status
        {
          processed_count: @processed_count,
          failed_count: @failed_count,
          running: running?
        }
      end

      private

      def logger
        ::Foreman::Logging.logger('katello/katello_events')
      end

      def run_event(event)
        logger.debug("event_queue_event: type=#{event.event_type}, object_id=#{event.object_id}")

        event_instance = nil
        begin
          ::User.as_anonymous_admin do
            event_instance = ::Katello::EventQueue.create_instance(event)
            event_instance.run
          end
          @processed_count += 1
        rescue => e
          @failed_count += 1
          logger.error("event_queue_error: type=#{event.event_type}, object_id=#{event.object_id}")
          logger.error(e.message)
          logger.error(e.backtrace.join("\n"))
        ensure
          if event_instance.try(:retry)
            result = ::Katello::EventQueue.reschedule_event(event)
            if result == :expired
              logger.warn("event_queue_event_expired: type=#{event.event_type} object_id=#{event.object_id}")
            elsif !result.nil?
              logger.warn("event_queue_rescheduled: type=#{event.event_type} object_id=#{event.object_id}")
            end
          end
          ::Katello::EventQueue.clear_events(event.event_type, event.object_id, event.created_at)
        end
      end

      def poll_for_events
        loop do
          break if @close

          until (event = ::Katello::EventQueue.next_event).nil?
            run_event(event)
          end
          sleep SLEEP_INTERVAL
        end
      rescue => e
        logger.error("Fatal error in Katello Event Monitor: #{e.message}")
      end
    end
  end
end
