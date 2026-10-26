module Katello
  module Applicability
    class Scheduler
      def initialize(queue: ApplicableHostQueue)
        @queue = queue
      end

      def process
        @queue.pop_hosts do |host_ids|
          Rails.logger.info "Processing batch #{host_ids.length}"
          ForemanTasks.async_task(Actions::Katello::Applicability::Hosts::BulkGenerate, host_ids: host_ids)
        end
      end

      class Benchmark
        def self.run(count: 1500)
          Katello::HostQueueElement.delete_all
          ForemanTasks::Task::DynflowTask.for_action(Actions::Katello::Applicability::Hosts::BulkGenerate).destroy_all
          Katello::Host::ContentFacet.trigger_applicability_generation((1..count).to_a)

          @result = ::Benchmark.bm do |x|
            x.report do
              until Katello::HostQueueElement.none?
                Rails.logger.info "#{Katello::HostQueueElement.count} hosts left to process"
                sleep 1
              end
            end
          end
        end

        def self.last_result
          @result
        end
      end

      class Actor
        def initialize
          @scheduler = ::Katello::Applicability::Scheduler.new
        end

        def start
        end

        def tick
          @scheduler.process
        end

        def start_timer?
          true
        end

        def timer_options
          {
            execution_interval: 3,
            interval_type: :fixed_rate,
          }
        end
      end
    end
  end
end
