require 'katello_test_helper'

module Katello
  module Applicability
    class SchedulerTest < ActiveSupport::TestCase
      let(:scheduler) { Katello::Applicability::Scheduler.new }
      let(:bulk_generate) { Actions::Katello::Applicability::Hosts::BulkGenerate }

      def test_process_empty_queue
        ForemanTasks.expects(:async_task).never

        scheduler.process
      end

      def test_process_triggers_bulk_generate
        ApplicableHostQueue.push_hosts([1, 2, 3])
        ForemanTasks.expects(:async_task).with(bulk_generate, host_ids: [1, 2, 3]).once

        scheduler.process

        assert_empty HostQueueElement.all
      end

      def test_process_keeps_hosts_queued_when_task_fails
        ApplicableHostQueue.push_hosts([1, 2])
        ForemanTasks.expects(:async_task).raises(StandardError)

        assert_raises(StandardError) { scheduler.process }

        assert_equal [1, 2], HostQueueElement.order(:id).pluck(:host_id)
      end
    end
  end
end
