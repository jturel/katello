require 'katello_test_helper'

module ::Actions::Katello::Host::Package
  class TestBase < ActiveSupport::TestCase
    include Dynflow::Testing
    #include Support::Actions::Fixtures

    let(:content_facet) { mock('a_system', uuid: 'uuid').mimic!(::Katello::Host::ContentFacet) }
    let(:host) do
      host_mock = mock('a_host', content_facet: content_facet, id: 42).mimic!(::Host::Managed)
      host_mock.stubs('name').returns('foobar')
      host_mock
    end

    let(:action) do
      action = create_action action_class
      action.stubs(:action_subject).with(host, :hostname => host.name, :packages => packages = %w(vim vi))
      plan_action action, host, packages
    end

    let(:dispatch_history) { stub('dispatch history', id: 100).mimic!(::Katello::Agent::DispatchHistory) }
  end

  class InstallTest < TestBase
    let(:action_class) { ::Actions::Katello::Host::Package::Install }

    def test_run
      ::Katello::Agent::Dispatcher.expects(:install_package).returns(dispatch_history)

      run_action action
    end

    def test_humanized_output
      Actions::Katello::Agent::DispatchHistoryPresenter.any_instance.expects(:humanized_output)

      action.humanized_output
    end

    describe '#humanized_output' do
=begin
      let :action do
        create_action(action_class).tap do |action|
          action.stubs(planned_actions: [pulp_action])
        end
      end
      let(:pulp_action) { fixture_action(pulp_action_class, output: fixture_variant) }

      describe 'successfully installed' do
        let(:fixture_variant) { :success }

        specify do
          assert_equal action.humanized_output, <<~OUTPUT.chomp
            1:emacs-23.1-21.el6_2.3.x86_64
            libXaw-1.0.11-2.el6.x86_64
            libXmu-1.1.1-2.el6.x86_64
            libotf-0.9.9-3.1.el6.x86_64
          OUTPUT
        end
      end

      describe 'no packages installed' do
        let(:fixture_variant) { :no_packages }

        specify do
          assert_equal 'No new packages installed', action.humanized_output
        end
      end

      describe 'with error' do
        let(:fixture_variant) { :error }

        specify do
          assert_equal action.humanized_output, <<~MSG.chomp
            No new packages installed
            emacss: No package(s) available to install
          MSG
        end
      end
=end
    end

    class RemoveTest < TestBase
      let(:action_class) { ::Actions::Katello::Host::Package::Remove }

      def test_run
        ::Katello::Agent::Dispatcher.expects(:remove_package).returns(dispatch_history)

        run_action action
      end

      def test_humanized_output
        Actions::Katello::Agent::DispatchHistoryPresenter.any_instance.expects(:humanized_output)

        action.humanized_output
      end

=begin
      describe '#humanized_output' do
        let :action do
          create_action_presentation(action_class).tap do |action|
            action.stubs(planned_actions: [pulp_action])
          end
        end
        let(:pulp_action) { fixture_action(pulp_action_class, output: fixture_variant) }

        describe 'successfully uninstalled' do
          let(:fixture_variant) { :success }

          specify do
            assert_equal action.humanized_output, <<~OUTPUT.chomp
              1:emacs-23.1-21.el6_2.3.x86_64
              libXaw-1.0.11-2.el6.x86_64
              libXmu-1.1.1-2.el6.x86_64
              libotf-0.9.9-3.1.el6.x86_64
            OUTPUT
          end
        end

        describe 'no packages uninstalled' do
          let(:fixture_variant) { :no_packages }

          specify do
            assert_equal 'No packages removed', action.humanized_output
          end
        end
      end
=end
    end
  end
end
