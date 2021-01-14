require 'katello_test_helper'

module Actions
  module Katello
    module Agent
      class DispatchHistoryPresenterTest < ActiveSupport::TestCase
        let(:action_type) { @action_type || :content_install }
        let(:dispatch_history) { stub(status: @status) }
        let(:presenter) { Actions::Katello::Agent::DispatchHistoryPresenter.new(dispatch_history, action_type) }

        def test_humanized_output_rpm
          @status = {
            "rpm" => {
              "details" => {
                "resolved" => [
                  {"name"=>"emacs", "qname"=>"1:emacs-23.1-21.el6_2.3.x86_64", "epoch"=>"1", "version"=>"23.1", "release"=>"21.el6_2.3", "arch"=>"x86_64", "repoid"=>"eng-Server"}
                ],
               "deps" => [
                 {"name"=>"libXmu", "qname"=>"libXmu-1.1.1-2.el6.x86_64", "epoch"=>"0", "version"=>"1.1.1", "release"=>"2.el6", "arch"=>"x86_64", "repoid"=>"eng-Server"},
                 {"name"=>"libXaw", "qname"=>"libXaw-1.0.11-2.el6.x86_64", "epoch"=>"0", "version"=>"1.0.11", "release"=>"2.el6", "arch"=>"x86_64", "repoid"=>"eng-Server"},
                 {"name"=>"libotf", "qname"=>"libotf-0.9.9-3.1.el6.x86_64", "epoch"=>"0", "version"=>"0.9.9", "release"=>"3.1.el6", "arch"=>"x86_64", "repoid"=>"eng-Server"}
               ]
             },
             "succeeded"=>true
            }
          }

          assert_equal presenter.humanized_output, <<~OUTPUT.chomp
            1:emacs-23.1-21.el6_2.3.x86_64
            libXaw-1.0.11-2.el6.x86_64
            libXmu-1.1.1-2.el6.x86_64
            libotf-0.9.9-3.1.el6.x86_64
          OUTPUT
        end

        def test_humanized_output_rpm_install_no_action
          @status = {
            "rpm" => {
              "details" => {
                "resolved" => [],
                "deps" => [],
                "succeeded" => true
              }
            }
          }

          assert_equal 'No new packages installed', presenter.humanized_output
        end

        def test_humanized_output_rpm_uninstall_no_action
          @action_type = :content_uninstall
          @status = {
            "rpm" => {
              "details" => {
                "resolved" => [],
                "deps" => [],
                "succeeded" => true
              }
            }
          }

          assert_equal 'No packages removed', presenter.humanized_output
        end
      end
    end
  end
end
