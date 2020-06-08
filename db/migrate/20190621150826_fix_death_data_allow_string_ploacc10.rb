# Convert fields to string (to allow unexpected alphanumerics)
# Recent Model 204 and LEDR data supplied single digits or empty strings.
# Old Model 204 data (pre 2001) also sometimes had value '@'.
class FixDeathDataAllowStringPloacc10 < ActiveRecord::Migration[5.2]
  def up
    change_column :death_data, 'ploacc10', :string
  end

  def down; end
end
