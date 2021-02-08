require 'katello_test_helper'
require_relative '../../../app/lib/katello/event_daemon/monitor.rb'

module Katello
  module EventDaemon
    class MonitorTest < ActiveSupport::TestCase
      class MockService
      end

      def setup
        @monitor = Katello::EventDaemon::Monitor.new(mock_service: MockService)
        @mock_status = {
          processed_count: 1,
          failed_count: 0,
          running: true
        }
      end

      def test_check_services
        service = stub(run: true, status: @mock_status)
        MockService.expects(:new).once.returns(service)
        service.expects(:run).once
        Rails.cache.expects(:write).twice.with("katello_event_daemon_status", mock_service: @mock_status)
        @monitor.check_services
        @monitor.check_services
      end

      def test_start_with_stop
        @monitor.stop
        @monitor.expects(:check_services).never
        @monitor.start
      end
    end
  end
end
