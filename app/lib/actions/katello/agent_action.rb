module Actions
  module Katello
    class AgentAction < Actions::EntryAction
      include Helpers::Presenter

      def dispatch_agent_action
        fail NotImplementedError
      end

      def run(event = nil)
        case event
        when nil
          suspend do |suspended_action|
            history = dispatch_agent_action

            history.host_id = input[:host_id]
            history.dynflow_execution_plan_id = suspended_action.execution_plan_id
            history.dynflow_step_id = suspended_action.step_id
            history.save!

            output[:dispatch_history_id] = history.id
          end
          schedule_timeout(Setting['content_action_accept_timeout'])
        when :finished
          Rails.logger.info("\n\n\nRESUMING ACTION????\n\n\n")
        end
      end

      def presenter
        Actions::Katello::Agent::DispatchHistoryPresenter.new(self)
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Skip
      end
    end
  end
end
