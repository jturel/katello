module Katello
  module Agent
    module Connection
      extend ActiveSupport::Concern

      included do
        @agent_connection = Katello::Qpid::Connection.new

        at_exit do
          close_connection
        end

        def self.send_message(message, history)
          translated = translate_message(message, history)
          @agent_connection.send_message("pulp.agent.#{message.consumer_id}", translated)
        end

        def self.fetch_agent_messages(sleep_seconds:)
          @agent_connection.receive_messages(
            address: settings[:queue_name],
            sleep_seconds: sleep_seconds
          ) do |received|
            yield(received)
          end
        end

        def self.close_connection
          @agent_connection.close
        end

        def self.settings
          SETTINGS[:katello][:agent]
        end

        def self.translate_message(katello_message, history)
          content = katello_message.json
          content[:data]['dispatch_history_id'] = history.id
          {
            content: content.to_json
          }
        end
      end
    end
  end
end
