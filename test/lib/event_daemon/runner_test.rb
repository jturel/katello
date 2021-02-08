require 'katello_test_helper'

module Katello
  module EventDaemon
    class RunnerTest < ActiveSupport::TestCase
      def setup
#        Katello::EventDaemon::Runner.instance_variable_set("@services", {})
#        Katello::EventDaemon::Runner.register_service(:mock_service, MockService)
#        Katello::EventDaemon::Runner.stubs(:runnable?).returns(true)
#        Katello::EventDaemon::Runner.stubs(:pid_file).returns(Rails.root.join('tmp', 'test_katello_daemon.pid'))
        @lockfile = Rails.root.join('tmp', 'test_katello_daemon.pid')
        File.unlink(@lockfile) if File.exist?(@lockfile)
        Katello::EventDaemon::Runner.stubs(:pid_file).returns(@lockfile)
      end

      def test_register_service
        assert Katello::EventDaemon::Runner.register_service(:mock_service, Object)
      end

      def test_start_stop
        monitor = mock('monitor', start: true, stop: true, stop_services: true)
        Katello::EventDaemon::Monitor.expects(:new).returns(monitor)

        Katello::EventDaemon::Runner.start
        assert Katello::EventDaemon::Runner.started?

        Katello::EventDaemon::Runner.stop
        refute File.exist?(@lockfile)
        refute Katello::EventDaemon::Runner.started?
      end

      def test_start_monitor
        monitor = mock('monitor')
        monitor.expects(:start).raises(StandardError)
        Katello::EventDaemon::Monitor.expects(:new).returns(monitor)
        Katello::EventDaemon::Runner.expects(:stop).twice
        Katello::EventDaemon::Runner.expects(:start)

        Katello::EventDaemon::Runner.start_monitor
      ensure
        Katello::EventDaemon::Runner.stop
      end

      def test_service_status
        expected_status = {
          running: true,
          processed_count: 1,
          failed_count: 0
        }
        Rails.cache.expects(:read).returns(mock_service: expected_status)
        result = Katello::EventDaemon::Runner.service_status(:mock_service)
        assert_equal result, expected_status
      end
    end
  end
end
