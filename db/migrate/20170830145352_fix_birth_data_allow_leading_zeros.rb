# Convert fields to string (to allow unexpected alphanumerics, or leading zeros)
class FixBirthDataAllowLeadingZeros < ActiveRecord::Migration[5.0]
  def up
    change_column :birth_data, :birthwgt, :string # Strings with leading zeros
    change_column :birth_data, :multtype, :string # Strings with leading zeros
    # change_column :birth_data, :gestatn, :string # Strings with leading zeros
    change_column :birth_data, :durmar, :string # Strings with leading zeros
  end

  def down
  end
end
