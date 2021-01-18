module Katello
  module Agent
    class ClientMessageHandler
      def self.logger
        ::Foreman::Logging.logger('katello/agent')
      end

      def self.handle(message)
        logger.info("id: #{message.message_id}, subject: #{message.subject}, content: #{message.content}")

        begin
          json = JSON.parse(message.content)
        rescue
          logger.error("could not parse message content into json")
          return
        end

        result_details = json.dig('result', 'retval', 'details')
        unless result_details
          logger.info("not processing this message")
          return
        end

        dispatch_history_id = json.dig('data', 'dispatch_history_id')
        unless dispatch_history_id
          logger.warn("No dispatch history in message. Nothing to do")
          return
        end

        dispatch_history = Katello::Agent::DispatchHistory.find_by_id(dispatch_history_id)
        unless dispatch_history
          logger.error("Dispatch history %s could not be found" % dispatch_history_id)
          return
        end

        dispatch_history.status = result_details
        dispatch_history.save!
      end
    end
  end
end
