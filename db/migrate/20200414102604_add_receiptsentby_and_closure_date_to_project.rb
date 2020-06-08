class AddReceiptsentbyAndClosureDateToProject < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :receiptsentby, :string
    add_column :projects, :closure_date,  :date
  end
end
