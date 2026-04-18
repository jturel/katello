module Katello
  module Applicability
    class Scheduler
      ActiveSupport::Notifications.subscribe("applicability_push_hosts") do |event|
        if event.payload[:host_ids].any?
          schedule_drain
        end
      end

      DRAIN_SLEEP_SECONDS = 1
      DRAIN_MUTEX = Mutex.new

      def self.initialize_agent
        ForemanTasks.dynflow.world.register_agent('applicability', value: nil)
      end

      module Agent
        class DrainHosts
          def run(_value)
            depth = Katello::Applicability::Scheduler.queue.queue_depth
            return if depth == 0

            if depth < Katello::ApplicableHostQueue.batch_size
              Rails.logger.info "Delaying drain start by 1s"
              sleep DRAIN_SLEEP_SECONDS
            end

            Katello::Applicability::Scheduler.drain_loop
          end
        end
      end

      def self.schedule_drain
        ForemanTasks.dynflow.world.agent_event('applicability', Agent::DrainHosts, [])
      end

      def self.queue
        Katello::ApplicableHostQueue
      end

      def self.drain_loop
        catch(:done) do
          loop do
            queue.pop_hosts do |batch|
              throw(:done) if batch.empty?
              ForemanTasks.async_task(Actions::Katello::Applicability::Hosts::BulkGenerate, host_ids: batch)
              if batch.length < queue.batch_size
                Rails.logger.info "drain sleeping a bit"
                sleep 0.5
              end
            end
          end
        end
      end
    end
  end
end
