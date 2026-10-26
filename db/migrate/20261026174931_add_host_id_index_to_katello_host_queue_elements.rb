class AddHostIdIndexToKatelloHostQueueElements < ActiveRecord::Migration[7.0]
  def change
    add_index :katello_host_queue_elements, :host_id
  end
end
