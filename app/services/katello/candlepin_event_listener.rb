module Katello
  # TODO: Move this class to app/lib/katello/event_daemon/services with other service definitions
  class CandlepinEventListener
    Event = Struct.new(:subject, :content)

    cattr_accessor :client_factory

    def self.blocking
      false
    end

    def initialize
      @client = self.class.client_factory.call
      @failed_count = 0
      @processed_count = 0
    end

    def run
      @client.subscribe do |message|
        handle_message(message)
      end
    end

    def running?
      @client.running?
    end

    def close
      @client.close
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
      ::Foreman::Logging.logger('katello/candlepin_events')
    end

    def handle_message(message)
      subject = "#{message.headers['EVENT_TARGET']}.#{message.headers['EVENT_TYPE']}".downcase
      cp_event = Event.new(subject, message.body)
      Rails.application.executor.wrap do
        ::Katello::Candlepin::EventHandler.new(logger).handle(cp_event)
      end
      @processed_count += 1
    rescue => e
      @failed_count += 1
      logger.error("Error handling Candlepin event")
      logger.error(e.message)
      logger.error(e.backtrace.join("\n"))
    end
  end
end
