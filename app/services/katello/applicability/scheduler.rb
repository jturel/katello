module Katello
  module Applicability
    class Scheduler
      ActiveSupport::Notifications.subscribe("applicability_push_hosts") do |event|
        if event.payload[:host_ids].any?
          agent_push_hosts(event.payload[:host_ids])
        end
      end

      def self.initialize_agent
        # TODO: initialize with current host_ids on the queue
        ForemanTasks.dynflow.world.register_agent('applicability', value: [], observers: [Agent::Observer.new])
      end

      module Agent
        class Observer
          def update(_time, old_value, new_value)
            return unless new_value.length > old_value.length # Hosts pushed

            queue_depth = Applicability::Scheduler.queue.queue_depth
            batch_size = Applicability::Scheduler.queue.batch_size
            full_batch = new_value.length == batch_size
            return unless full_batch || new_value.length == queue_depth # this might break

            Katello::Applicability::Scheduler.queue.pop_host_ids(new_value) do |batch|
              Rails.logger.info "[applicability] Draining hosts=#{new_value.length} queue_depth=#{queue_depth} batch=#{batch.length}"
              ForemanTasks.async_task(Actions::Katello::Applicability::Hosts::BulkGenerate, host_ids: batch)
            end

            Applicability::Scheduler.schedule_pop(new_value)
          end
        end

        class PushHosts
          def initialize(host_ids)
            @host_ids = host_ids
          end

          def run(value)
            value + @host_ids
          end
        end

        class PopHosts
          def initialize(host_ids)
            @host_ids = host_ids
          end

          def run(value)
            value - @host_ids
          end
        end
      end

      def self.agent_push_hosts(host_ids)
        ForemanTasks.dynflow.world.agent_event('applicability', Agent::PushHosts, [host_ids])
      end

      def self.schedule_pop(host_ids)
        ForemanTasks.dynflow.world.agent_event('applicability', Agent::PopHosts, [host_ids])
      end

      def self.queue
        Katello::ApplicableHostQueue
      end
    end
  end
end
