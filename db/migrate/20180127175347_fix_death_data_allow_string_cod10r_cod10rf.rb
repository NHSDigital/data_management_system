# Convert fields to string (to allow unexpected alphanumerics)
# LEDR supplies cod10r and cod10rf values as 'a', 'b', 'c', 'd'
# Model 204 gave them as 1, 2, 3, 4, 10, 11, 12
class FixDeathDataAllowStringCod10rCod10rf < ActiveRecord::Migration[5.0]
  def up
    (1..20).each do |i|
      change_column :death_data, "cod10r_#{i}", :string # Strings with leading zeros
      change_column :death_data, "cod10rf_#{i}", :string # Strings with leading zeros
    end
  end

  def down
  end
end
