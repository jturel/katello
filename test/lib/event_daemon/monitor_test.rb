require 'katello_test_helper'
require_relative '../../../app/lib/katello/event_daemon/monitor.rb'

module Katello
  module EventDaemon
    class MonitorTest < ActiveSupport::TestCase
      class MockService
      end

      let(:service_class) { MockService }
      let(:monitor) { Katello::EventDaemon::Monitor.new(mock_service: service_class) }

      def setup
        @mock_status = {
          processed_count: 1,
          failed_count: 0,
          running: true
        }
      end

      def test_check_services_running
        service = stub(run: true, status: @mock_status)
        service_class.expects(:new).once.returns(service)
        service.expects(:run).once
        Thread.expects(:new).never
        monitor.check_services
        monitor.check_services
      end

      def test_check_services_blocking_service
        service = stub(run: true, status: @mock_status)
        service_class.expects(:new).once.returns(service)
        service_class.expects(:blocking).returns(true)
        Thread.expects(:new).once
        monitor.check_services
        monitor.check_services
      end

      def test_stop_services

      end

      def test_start_with_stop
        monitor.stop
        monitor.expects(:check_services).never
        monitor.start
      end
    end
  end
end
