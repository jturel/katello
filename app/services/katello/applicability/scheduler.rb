module Katello
  module Applicability
    class Scheduler
      ActiveSupport::Notifications.subscribe("schedule_host_applicability") do |event|
        if event.payload[:host_ids].any?
          notify_actor(event.payload[:host_ids])
        end
      end

      def self.notify_actor(host_ids)
        ForemanTasks.dynflow.world.message_actor('applicability', 'push_hosts', [host_ids])
      end

      def initialize
        @backlog = Backlog.new
        @storage = ApplicableHostQueue
        @processor = BatchProcessor.new
      end

      def push_hosts(host_ids)
        @backlog.add(host_ids)
      end

      def done?
        @backlog.empty?
      end

      def load_from_storage
        host_ids = @storage.pop_hosts
        push_hosts(host_ids)
      end

      def persist
        @storage.push_hosts(@backlog.host_ids)
      end

      def process
        processed = @processor.process(@backlog.host_ids)
        @backlog.remove(processed)
        @last_processed = Time.zone.now
      end

      def needs_processing?
        return false if @backlog.empty?

        @last_processed.nil? || @last_processed < 2.seconds.ago || @backlog.size >= @processor.batch_size
      end

      class Benchmark
        def self.run(count: 1500, threads: 20)
          Katello::HostQueueElement.delete_all
          ForemanTasks::Task::DynflowTask.for_action(Actions::Katello::Applicability::Hosts::BulkGenerate).destroy_all
          @result = ::Benchmark.bm do |x|
            x.report do
              host_id = Concurrent::AtomicFixnum.new
              count.times do
                spawned_threads = [].tap do |arr|
                  threads.times { arr << Thread.new { Scheduler.notify_actor([host_id.increment]) } }
                end
                spawned_threads.map(&:join)
              end
            end
          end
        end

        def self.last_result
          @result
        end
      end

      class Actor < Concurrent::Actor::RestartingContext
        def initialize(scheduler: Scheduler.new)
          super()
          @scheduler = scheduler
          # TODO: What's the proper interval type?
          @timer = Concurrent::TimerTask.new(execution_interval: 0.5, interval_type: :fixed_rate) do
            reference.tell(:tick)
          end
          reference.tell(:initialize)
        end

        def on_message(message)
          action, arg = message
          case action
          when :initialize
            @scheduler.load_from_storage
          when :push_hosts
            @scheduler.push_hosts(arg)
          when :tick
            @scheduler.process if @scheduler.needs_processing?
          when :terminate
            @timer.shutdown
            @scheduler.persist
            arg.fulfill(true)
            return
          end

          if @scheduler.done?
            @timer.shutdown
          else
            @timer.execute
          end
        end
      end
    end
  end
end
