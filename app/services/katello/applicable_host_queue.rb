module Katello
  class ApplicableHostQueue
    def self.batch_size
      Setting["applicability_batch_size"]
    end

    def self.queue_depth
      ::Katello::HostQueueElement.all.size
    end

    def self.push_hosts(ids)
      return if ids.empty?
      ActiveSupport::Notifications.instrument("applicability_push_hosts") do |payload|
        result = HostQueueElement.insert_all(ids.map { |host_id| { host_id: host_id } }, returning: :host_id, unique_by: :host_id)
        payload[:host_ids] = result.rows.flatten
      end
    end

    def self.pop_hosts
      HostQueueElement.transaction do
        elements = HostQueueElement.order(:id).select(:id, :host_id).limit(batch_size)

        host_ids = elements.map(&:host_id)
        yield(host_ids) if block_given?

        elements.delete_all
        host_ids
      end
    end

    def self.pop_host_ids(ids)
      HostQueueElement.transaction do
        elements = HostQueueElement.order(:id).select(:id, :host_id).where(host_id: ids)

        host_ids = elements.map(&:host_id)
        yield(host_ids) if block_given?

        elements.delete_all
        host_ids
      end
    end
  end
end
