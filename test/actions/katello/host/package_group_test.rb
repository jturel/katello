require_relative '../agent_action_tests.rb'

module ::Actions::Katello::Host::PackageGroup
  class InstallTest < ActiveSupport::TestCase
    include Actions::Katello::AgentActionTests

    let(:action_class) { ::Actions::Katello::Host::PackageGroup::Install }

    let(:action) do
      action = create_action action_class
      action.stubs(:action_subject).with(host, :groups => package_groups = %w(backup))
      plan_action action, host, package_groups
    end

    let(:dispatcher_method) { :install_package_group }
  end

  class RemoveTest < ActiveSupport::TestCase
    include Actions::Katello::AgentActionTests

    let(:action_class) { ::Actions::Katello::Host::PackageGroup::Remove }

    let(:action) do
      action = create_action action_class
      action.stubs(:action_subject).with(host, :groups => package_groups = %w(backup))
      plan_action action, host, package_groups
    end

    let(:dispatcher_method) { :install_package_group }
  end
end
