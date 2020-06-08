class CreateCostRecoveries < ActiveRecord::Migration[5.2]
  def change
    create_table :cost_recoveries do |t|
      t.references :project
      t.boolean :cost_recovery_applied, default: false
      # t.references :fec_waived_reason # TODO: need lookup table
      t.decimal :quote_cost, precision: 8, scale: 2
      t.decimal :actual_cost, precision: 8, scale: 2
      t.datetime :invoice_request_date
      t.string :phe_customer_number
      t.string :purchase_order_number
      t.string :phe_invoice_number
      t.string :invoiced_financial_year

      t.timestamps
    end
  end
end
