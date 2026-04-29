module Katello
  module Applicability
    class BatchProcessor
      def batch_size
        Setting["applicability_batch_size"]
      end

      def batch(host_ids)
        host_ids.take(batch_size)
      end

      def process(host_ids)
        current_batch = batch(host_ids)
        Rails.logger.info "Processing batch #{current_batch.length}"
        #ForemanTasks.async_task(Actions::Katello::Applicability::Hosts::BulkGenerate, host_ids: current_batch)
        current_batch
      end
    end
  end
end
