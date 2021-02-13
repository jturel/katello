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
        service = mock(run: true)
        service.expects(:status).twice.returns(@mock_status)
        service_class.expects(:new).once.returns(service)
        monitor.check_services
        monitor.check_services
      end

      def test_check_services_blocking_service
        service = mock(run: true)
        service.expects(:status).twice.returns(@mock_status)
        service_class.expects(:new).once.returns(service)
        service_class.expects(:blocking).returns(true)
        service.expects(:run).never # this happens in a thread
        monitor.check_services
        monitor.check_services
      end

      def test_check_services_no_raise_error
        service = mock(close: true)
        service_class.expects(:new).once.returns(service)
        service.expects(:run).raises(StandardError)
        monitor.check_services
      end

      def test_stop_services
        service = mock(run: true, status: @mock_status, close: true)
        service_class.expects(:new).once.returns(service)
        monitor.check_services

        monitor.stop_services
      end

      def test_stop_services_no_raise_error
        service = mock(run: true, status: @mock_status)
        service.expects(:close).raises(StandardError)
        service_class.expects(:new).once.returns(service)
        monitor.check_services

        monitor.stop_services
      end

      def test_start_with_stop
        monitor.stop
        monitor.expects(:check_services).never
        monitor.start
      end
    end
  end
end
