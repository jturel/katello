require 'katello_test_helper'

module Katello
  module Agent
    class ClientMessageHandlerTest < ActiveSupport::TestCase
      def setup
        @host = hosts(:one)
      end

      def test_handle_with_dispatch_history
        dispatch_history = Katello::Agent::DispatchHistory.create!(
          host_id: @host.id,
          dynflow_execution_plan_id: '12345',
          dynflow_step_id: 2
        )

        ::ForemanTasks::Task.create!(
          external_id: '12345',
          result: 'pending'
        )

        content = {
          data: {
            dispatch_history_id: dispatch_history.id
          },
          result: "succeeded"
        }

        message = stub(message_id: '12345', subject: nil, content: content.to_json)
        assert ClientMessageHandler.handle(message)
      end
    end
  end
end
