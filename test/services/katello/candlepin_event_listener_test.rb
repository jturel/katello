require 'katello_test_helper'

module Katello
  class CandlepinEventListenerTest < ActiveSupport::TestCase
    let(:listener) { Katello::CandlepinEventListener.new }

    def setup
      @status = {
        processed_count: 0,
        failed_count: 0,
        running: false
      }
    end

    def test_run_close
      client = mock('client', close: true, subscribe: true)
      Katello::CandlepinEventListener.expects(:client_factory).returns(proc { client })

      listener.run

      listener.close
    end

    def test_status
      assert_equal @status, listener.status
    end

    def test_status_running
      client = mock('client', subscribe: true, running?: true)
      Katello::CandlepinEventListener.expects(:client_factory).returns(proc { client })

      listener.run
      assert true, listener.status[:running]
    end

    def test_handle_message
      message = stub(headers: {'EVENT_TYPE' => 'updated', 'EVENT_TARGET' => 'CONSUMER'}, body: 'the body')

      Katello::CandlepinEventListener::Event.expects(:new).with('consumer.updated', 'the body')
      Candlepin::EventHandler.any_instance.expects(:handle)

      listener.handle_message(message)
    end
  end
end
