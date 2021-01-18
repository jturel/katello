module Actions
  module Katello
    class AgentAction < Actions::EntryAction
      include Actions::Base::Polling
      include Helpers::Presenter

      def dispatch_agent_action
        fail NotImplementedError
      end

      def agent_action_type
        nil
      end

      def run(event = nil)
        unless event == Dynflow::Action::Skip
          super
        end
      end

      def done?
        dispatch_history&.status&.present?
      end

      def invoke_external_task
        history = dispatch_agent_action

        history.host_id = input[:host_id]
        history.save!

        output[:dispatch_history_id] = history.id
        schedule_timeout(accept_timeout)
      end

      def poll_external_task
        progress = 0.10

        if dispatch_history&.status&.present?
          progress = 1
        end

        {
          progress: progress
        }
      end

      def accept_timeout
        Setting['content_action_accept_timeout']
      end

      def finish_timeout
        Setting['content_action_finish_timeout']
      end

      def process_timeout
        unless output[:accept_time]
          fail _("Host did not respond within %s seconds. The task has been cancelled. Is katello-agent installed and goferd running on the Host?") % accept_timeout
        end

        if Time.now - DateTime.parse(output[:accept_time]) >= finish_timeout
          fail _("Host did not finish content action in %s seconds.  The task has been cancelled.") % finish_timeout
        end
      end

      def fail_on_errors
        errors = presenter.error_messages

        if errors.any?
          fail errors.join("\n")
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
