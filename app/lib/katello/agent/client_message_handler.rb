module Katello
  module Agent
    class ClientMessageHandler
      STATUSES = %w(accepted started).freeze

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

        result = json['result']

        unless result
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

        if dispatch_history.dynflow_execution_plan_id && dispatch_history.dynflow_step_id
          pending_task = ForemanTasks::Task.find_by(
            external_id: dispatch_history.dynflow_execution_plan_id,
            result: 'pending'
          )

          unless pending_task
            logger.warn("not handling event for invalid execution plan #{dispatch_history.dynflow_execution_plan_id}")
            return
          end

          #dispatch_history.data = json.dig('data', '')
          #dispatch_history.save!

          ForemanTasks.dynflow.world.event(dispatch_history.dynflow_execution_plan_id, dispatch_history.dynflow_step_id, :finished)
          logger.info("triggered finished event for execution plan #{dispatch_history.dynflow_execution_plan_id}")
        else
          logger.info("nothing to update in dynflow")
        end
      end
    end
  end
end
