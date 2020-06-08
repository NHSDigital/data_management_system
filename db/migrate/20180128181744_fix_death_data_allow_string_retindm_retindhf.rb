# Convert fields to string (to allow unexpected alphanumerics)
# LEDR supplies retindm and retindhf values as 'Y', 'N'
# Model 204 gave them as '1' and an empty string
class FixDeathDataAllowStringRetindmRetindhf < ActiveRecord::Migration[5.0]
  def up
    change_column :death_data, "retindm", :string
    change_column :death_data, "retindhf", :string
  end

  def down
  end
end
