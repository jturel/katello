module Katello
  module EventDaemon
    module Services
      class AgentEventReceiver
        class Handler
          attr_accessor :processed, :failed

          def initialize
            @processed = 0
            @failed = 0
          end

          def handle(message)
            Rails.application.executor.wrap do
              ::Katello::Agent::ClientMessageHandler.new(message).handle
              @processed += 1
            rescue => e
              @failed += 1
              Rails.logger.error("Error handling Katello Agent client message")
              Rails.logger.error(e.message)
              Rails.logger.error(e.backtrace.join("\n"))
            end
          end
        end

        def self.blocking
          true
        end

        def initialize
          @handler = Handler.new
          @connection = ::Katello::Agent::Connection.new
        end

        def run
          @connection.fetch_agent_messages(@handler)
        end

        def running?
          @connection.open?
        end

        def close
          @connection.close
        end

        def status
          {
            processed_count: @handler.processed,
            failed_count: @handler.failed,
            running: running?
          }
        end

        private

        def logger
          ::Foreman::Logging.logger('katello/agent')
        end
      end
    end
  end
end
