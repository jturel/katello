require 'katello_test_helper'

module Katello
  module EventMonitor
    class PollerThreadTest < ActiveSupport::TestCase
      let(:poller) { Katello::EventMonitor::PollerThread.new }

      def test_run
        poller.expects(:poll_for_events)
        poller.run
      end

      def test_run_event
        event = Katello::Event.new(object_id: 100, event_type: 'import_host_applicability')
        Katello::Events::ImportHostApplicability.any_instance.expects(:run)

        poller.run_event(event)
      end

      def test_status
        status = {
          processed_count: 0,
          failed_count: 0,
          running: false
        }

        assert_equal status, poller.status
      end

      def test_status_running
        thread = Thread.new do
          poller.run
        end
        sleep Katello::EventMonitor::PollerThread::SLEEP_INTERVAL + 0.1

        assert poller.status[:running]

        poller.close
        sleep Katello::EventMonitor::PollerThread::SLEEP_INTERVAL + 0.1
        refute poller.status[:running]
        refute thread.status
      end
    end
  end
end
