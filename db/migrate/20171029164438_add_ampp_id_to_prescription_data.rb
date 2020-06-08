class AddAmppIdToPrescriptionData < ActiveRecord::Migration[5.0]
  def change
    add_column :prescription_data, :pf_id, :bigint
    add_column :prescription_data, :ampp_id, :bigint
    add_column :prescription_data, :vmpp_id, :bigint
  end
end
