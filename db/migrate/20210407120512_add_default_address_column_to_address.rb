# plan.io 22297
# Add default_address column to Organisation table
class AddDefaultAddressColumnToAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :addresses, :default_address, :boolean
  end
end
