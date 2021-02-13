require 'katello_test_helper'

module Katello
  module EventDaemon
    module Services
      class AgentEventReceiverTest < ActiveSupport::TestCase
        let(:receiver) { Katello::EventDaemon::Services::AgentEventReceiver.new }

        def setup
          @mock_status = {
            processed_count: 0,
            failed_count: 0,
            running: false
          }
        end

        def test_run
          connection = mock(fetch_agent_messages: true)
          Katello::Agent::Connection.expects(:new).returns(connection)
          receiver.run
        end

        def test_close
          connection = mock(close: true)
          Katello::Agent::Connection.expects(:new).returns(connection)
          receiver.close
        end

        def test_status
          assert_equal @mock_status, receiver.status
        end
      end
    end
  end
end
