class CreateReleases < ActiveRecord::Migration[6.0]
  def change
    create_table :releases do |t|
      t.references :project,               foreign_key: true
      t.references :project_state,         foreign_key: { to_table: :workflow_project_states }
      t.datetime   :invoice_requested_date
      t.datetime   :invoice_sent_date
      t.string     :phe_invoice_number
      t.string     :po_number
      t.datetime   :ndg_opt_out_processed_date
      t.string     :cprd_reference
      t.decimal    :actual_cost,           precision: 10, scale: 2
      t.string     :vat_reg,               limit: 2, index: true
      t.string     :income_received,       limit: 2, index: true
      t.string     :cost_recovery_applied, limit: 2, index: true
      t.string     :drr_no
      t.string     :individual_to_release
      t.datetime   :release_date

      t.timestamps
    end

    add_foreign_key :releases, :propositions, column: :vat_reg
    add_foreign_key :releases, :propositions, column: :income_received
    add_foreign_key :releases, :propositions, column: :cost_recovery_applied
  end
end
