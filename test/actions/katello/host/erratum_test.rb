require 'katello_test_helper'

module ::Actions::Katello::Host::Erratum
  class TestBase < ActiveSupport::TestCase
    include Dynflow::Testing

    let(:errata_ids) { %w(RHBA-2014-1234 RHBA-2014-1235 RHBA-2014-1236 RHBA-2014-1237) }
    let(:host) { hosts(:one) }

    let(:action) do
      action = create_action action_class
      action.stubs(:action_subject).with(host, :hostname => host.name, :errata => errata = %w(RHBA-2014-1234))
      plan_action action, host, errata
    end

    let(:dispatch_history) { ::Katello::Agent::DispatchHistory.create!(host_id: host.id) }
  end

  class InstallTest < TestBase
    let(:action_class) { ::Actions::Katello::Host::Erratum::Install }

    def test_run
      ::Katello::Agent::Dispatcher.expects(:install_errata).returns(dispatch_history)

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
