module Actions
  module Katello
    class AgentAction < Actions::EntryAction
      include Actions::Base::Polling
      include Helpers::Presenter

      # Should these be cancellable like the pulp tasks?

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
            schedule_timeout(accept_timeout)
          end
        when Dynflow::Action::Timeouts::Timeout
          process_timeout
        when :accepted
          schedule_timeout(finish_timeout)
        when :failed
          fail_on_errors
        when :finished
          Rails.logger.info("\n\n\nRESUMING ACTION????\n\n\n")
        else
          fail_on_errors # is this needed?
        end
      end

      def accept_timeout
        Setting['content_action_accept_timeout']
      end

      def finish_timeout
        Setting['content_action_finish_timeout']
      end

      def process_timeout
        # accept timeout
        unless dispatch_history.accepted
          fail _("Host did not respond within %s seconds. The task has been cancelled. Is katello-agent installed and goferd running on the Host?") % accept_timeout
        end

        # finish timeout
        fail _("Host did not finish content action in %s seconds.  The task has been cancelled.") % finish_timeout
      end

      def fail_on_errors(dispatch_history = self.dispatch_history)
        errors = presenter.error_messages

        if errors.any?
          fail task_errors.join("\n")
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
