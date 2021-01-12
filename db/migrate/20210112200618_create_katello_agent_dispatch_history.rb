class CreateKatelloAgentDispatchHistory < ActiveRecord::Migration[6.0]
  def change
    create_table :katello_agent_dispatch_histories do |t|
      t.integer :host_id, null: false, foreign_key: true
      t.string :status
      t.string :dynflow_execution_plan_id
      t.integer :dynflow_step_id

      t.index [:host_id, :dynflow_execution_plan_id, :dynflow_step_id], unique: true, name: 'katello_agent_dispatch_histories_host_dynflow_fk'
    end
  end
end
