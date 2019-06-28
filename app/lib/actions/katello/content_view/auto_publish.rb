module Actions
  module Katello
    module ContentView
      class AutoPublish < Actions::Base
        #include Actions::Base::Polling
        include Dynflow::Action::Polling

        def plan(content_view, version_id)
          version = ::Katello::ContentViewVersion.find(version_id)
          description = _("Auto Publish - Triggered by '%s'") % version.name

          plan_action(::Actions::Katello::ContentView::Publish, content_view, description,
                                  :triggered_by => version)

          plan_self(content_view_id: content_view.id, version_id: version_id)
        end

        def humanized_name
          _("Auto Publish")
        end

        def invoke_external_task
        end

        def poll_external_task
        end

        def done?
          tasks = ForemanTasks::Task.running.where(label: 'Actions::Katello::ContentView::Publish')

          tasks.none? do |task|
            # are we already publishing this content view?
            not_done = task.input.dig("content_view", "id") == input[:content_view_id]
            action_logger.error("\n\n\nWAITING FOR PUBLISH ON CV #{input[:content_view_id]} to finish!!\n\n\n") if not_done
            not_done
          end
        end
      end
    end
  end
end
