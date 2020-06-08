class AlterContracts < ActiveRecord::Migration[6.0]
  def change
    change_table :contracts do |t|
      t.references :project_state, foreign_key: { to_table: :workflow_project_states }
      t.datetime   :contract_sent_date
      t.datetime   :contract_start_date
      t.datetime   :contract_end_date
      t.datetime   :contract_returned_date
      t.datetime   :contract_executed_date
      t.datetime   :advisory_letter_date
      t.datetime   :destruction_form_received_date
    end

    add_foreign_key :contracts, :projects
  end
end
