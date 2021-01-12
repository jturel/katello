module Actions
  module Katello
    module Host
      module Package
        class Install < Actions::EntryAction
#          include Helpers::Presenter

          def plan(host, packages)
            Type! host, ::Host::Managed

            action_subject(host, :hostname => host.name, :packages => packages)

            plan_self(:host_id => host.id, :consumer_uuid => host.content_facet.uuid, :packages => packages)
          end

          def run(event = nil)
            case event
            when nil
              suspend do |suspended_action|
                ::Katello::Agent::Dispatcher.install_package(
                  host_id: input[:host_id],
                  consumer_id: input[:consumer_uuid],
                  packages: input[:packages]
                ) do |_message, history|
                  history.dynflow_execution_plan_id = suspended_action.execution_plan_id
                  history.dynflow_step_id = suspended_action.step_id
                end
              end
            when :finished
              Rails.logger.info("\n\n\nRESUMING ACTION????\n\n\n")
            end
          end

          def humanized_name
            if input.try(:[], :hostname)
              _("Install package for %s") % input[:hostname]
            else
              _("Install package")
            end
          end

          def humanized_input
            [input[:packages].join(", ")] + super
          end

=begin
          def presenter
            Helpers::Presenter::Delegated.new(self, planned_actions(Pulp::Consumer::ContentInstall))
          end
=end

          def rescue_strategy
            Dynflow::Action::Rescue::Skip
          end

          def finalize
            host = ::Host.find_by(:id => input[:host_id])
            host.update(audit_comment: (_("Installation of package(s) requested: %{packages}") % {packages: input[:packages].join(", ")}).truncate(255))
          end
        end
      end
    end
  end
end
