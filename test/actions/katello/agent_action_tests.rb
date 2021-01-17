require 'katello_test_helper'

module Actions
  module Katello
    module AgentActionTests
      extend ActiveSupport::Concern
      include Dynflow::Testing

      included do
        let(:host) { hosts(:one) }

        let(:dispatch_history) { ::Katello::Agent::DispatchHistory.create!(host_id: host.id) }

        def test_run
          ::Katello::Agent::Dispatcher.expects(dispatcher_method).returns(dispatch_history)

          run_action action

          assert_equal host.id, dispatch_history.host_id
          refute_nil dispatch_history.dynflow_execution_plan_id
          refute_nil dispatch_history.dynflow_step_id
        end

        def test_humanized_output
          Actions::Katello::Agent::DispatchHistoryPresenter.any_instance.expects(:humanized_output)

          action.humanized_output
        end
      end
    end
  end
end
