module Actions
  module Katello
    class AgentAction < Actions::EntryAction
      include Helpers::Presenter

      def dispatch_agent_action
        fail NotImplementedError
      end

      def agent_action_type
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
        when :accepted
          schedule_timeout(Setting['content_action_finish_timeout'])
        when :failed
          check_error_details
        when :finished
          Rails.logger.info("\n\n\nRESUMING ACTION????\n\n\n")
        end
      end

=begin
      def check_error_details
          error_details = pulp_task.try(:[], "result").try(:[], "details").try(:[], "rpm").try(:[], "details").try(:[], "trace")
          error_message = pulp_task.try(:[], "result").try(:[], "details").try(:[], "rpm").try(:[], "details").try(:[], "message")
          error_details = presenter.rpm_error_trace
          error_message = presenter.rpm_error_message
          if presenter.rpm_error_trace&.include?("YumDownloadError")
          if error_details&.include?("YumDownloadError") && error_message
            fail _("An error occurred during the sync \n%{error_message}") % {:error_message => error_details}
          end
        end
      end
=end

      def presenter
        Actions::Katello::Agent::DispatchHistoryPresenter.new(dispatch_history, agent_action_type)
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Skip
      end

      def dispatch_history
        if output[:dispatch_history_id]
          ::Katello::Agent::DispatchHistory.find_by_id(output[:dispatch_history_id])
        end
      end
    end
  end
end
