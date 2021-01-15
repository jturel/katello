require 'katello_test_helper'

module Katello
  module Agent
    class DispatcherTest < ActiveSupport::TestCase
      def setup
        @host = hosts(:one)
      end

      def test_install_package
        Katello::Agent::Dispatcher.expects(:send_message)

        dispatch_history = Katello::Agent::Dispatcher.install_package(
          host_id: @host.id,
          packages: ['foo']
        )

        assert_equal @host.id, dispatch_history.host_id
      end

      def test_remove_package
        Katello::Agent::Dispatcher.expects(:send_message)

        dispatch_history = Katello::Agent::Dispatcher.remove_package(
          host_id: @host.id,
          packages: ['foo']
        )

        assert_equal @host.id, dispatch_history.host_id
      end

      def test_install_errata
        Katello::Agent::Dispatcher.expects(:send_message)

        dispatch_history = Katello::Agent::Dispatcher.install_errata(
          host_id: @host.id,
          errata_ids: ['foo']
        )

        assert_equal @host.id, dispatch_history.host_id
      end
    end
  end
end
