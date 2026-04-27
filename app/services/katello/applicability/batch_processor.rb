module Katello
  module Applicability
    class BatchProcessor
      def batch_size
        Setting["applicability_batch_size"]
      end

      def process(host_ids)
        batch = []
        host_ids.each do |host_id|
          break if batch.length == batch_size
          batch << host_id
        end

        Rails.logger.info "Processing batch #{batch.length}"
        # TODO: Spawn BulkGenerate

        batch
      end
    end
  end
end
