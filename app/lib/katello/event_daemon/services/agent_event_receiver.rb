module Katello
  module EventDaemon
    module Services
      class AgentEventReceiver
        include Katello::Agent::Connection

        def self.run
          fail("Katello agent event receiver already started") if status[:running]

          @thread = Thread.new do
            fetch_agent_messages(sleep_seconds: 2) do |received|
              ::Katello::Agent::ClientMessageHandler.handle(received)
            end
          end
        end

        def self.close
          @thread&.kill
          close_connection
          Rails.logger.info("AGENT EVENT RECEIVER CLOSED")
        end

        def self.status
          {running: @thread&.status.present?}
        end
      end
    end
  end
end
