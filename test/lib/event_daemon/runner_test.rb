require 'katello_test_helper'

module Katello
  module EventDaemon
    class RunnerTest < ActiveSupport::TestCase
      def setup
        @lockfile = Rails.root.join('tmp', "test_katello_daemon_#{SecureRandom.uuid}.pid")
        Katello::EventDaemon::Runner.stubs(:pid_file).returns(@lockfile)
      end

      def teardown
        File.unlink(@lockfile) if File.exist?(@lockfile)
      end

      def test_register_service
        assert Katello::EventDaemon::Runner.register_service(:mock_service, Object)
      end

      #Katello::EventDaemon::RunnerTest#test_start_stop [/home/vagrant/katello/app/lib/katello/event_daemon/runner.rb:43]:
      #unexpected invocation: #<Mock:monitor>.stop()
      def test_start_stop
        monitor = mock('start_stop_monitor', start: true, stop: true, stop_services: true)
        Katello::EventDaemon::Monitor.expects(:new).returns(monitor)

        Katello::EventDaemon::Runner.start
        sleep 0.1
        assert Katello::EventDaemon::Runner.started?

        Katello::EventDaemon::Runner.stop
        refute File.exist?(@lockfile)
        refute Katello::EventDaemon::Runner.started?
      end

      def test_start_monitor_error
        monitor = mock('start_monitor_monitor')
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
