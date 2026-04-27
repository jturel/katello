module Katello
  class ApplicableHostQueue
    def self.push_hosts(ids)
      return if ids.empty?
      HostQueueElement.insert_all(ids.map { |host_id| { host_id: host_id } }, unique_by: :host_id)
    end

    def self.pop_hosts
      elements = HostQueueElement.order(:id).select(:id, :host_id)

      host_ids = elements.map(&:host_id)
      yield(host_ids) if block_given?

      elements.delete_all
      host_ids
    end
  end
end
