module Katello
  class ApplicableHostQueue
    def self.batch_size
      Setting["applicability_batch_size"]
    end

    def self.push_hosts(ids)
      return if ids.empty?
      HostQueueElement.import ids.map { |host_id| { host_id: host_id } }, validate: false
    end

    def self.pop_hosts(amount: self.batch_size)
      max_id = HostQueueElement.maximum(:id)
      return [] unless max_id

      # Fething batch_size * 2 in case there are many duplicate hosts
      host_ids = HostQueueElement.where('id <= ?', max_id).order(:id).limit(amount * 2).pluck(:host_id).uniq.first(amount)
      yield host_ids if block_given?

      HostQueueElement.where(host_id: host_ids).where('id <= ?', max_id).delete_all
      host_ids
    end
  end
end
