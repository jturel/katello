require 'katello_test_helper'

module ::Actions::Katello::Host::Package
  class TestBase < ActiveSupport::TestCase
    include Dynflow::Testing

    let(:host) { hosts(:one) }

    let(:action) do
      action = create_action action_class
      action.stubs(:action_subject).with(host, :hostname => host.name, :packages => packages = %w(vim vi))
      plan_action action, host, packages
    end

    let(:dispatch_history) { ::Katello::Agent::DispatchHistory.create!(host_id: host.id) }
  end

  class InstallTest < TestBase
    let(:action_class) { ::Actions::Katello::Host::Package::Install }

    def test_run
      ::Katello::Agent::Dispatcher.expects(:install_package).returns(dispatch_history)

      run_action action

      dispatch_history.reload

      assert_equal host.id, dispatch_history.host_id
      refute_nil dispatch_history.dynflow_execution_plan_id
      refute_nil dispatch_history.dynflow_step_id
    end

    def test_humanized_output
      Actions::Katello::Agent::DispatchHistoryPresenter.any_instance.expects(:humanized_output)

      action.humanized_output
    end
  end

  class RemoveTest < TestBase
    let(:action_class) { ::Actions::Katello::Host::Package::Remove }

    def test_run
      ::Katello::Agent::Dispatcher.expects(:remove_package).returns(dispatch_history)

      run_action action

      dispatch_history.reload

      assert_equal host.id, dispatch_history.host_id
      refute_nil dispatch_history.dynflow_execution_plan_id
      refute_nil dispatch_history.dynflow_step_id
    end

    def test_humanized_output
      Actions::Katello::Agent::DispatchHistoryPresenter.any_instance.expects(:humanized_output)

      action.humanized_output
    end
  end
end
