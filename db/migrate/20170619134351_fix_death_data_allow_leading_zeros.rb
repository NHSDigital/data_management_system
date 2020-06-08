# Convert fields to string (to allow unexpected alphanumerics, or leading zeros)
# TODO: Define fields ctydpod, ctydr, marstat as alphanumeric, not numeric in the Death spec.
class FixDeathDataAllowLeadingZeros < ActiveRecord::Migration[5.0]
  def up
    change_column :death_data, :ctydpod, :string # Alphanumeric
    change_column :death_data, :ctypod, :string # Strings with leading zeros
    change_column :death_data, :doddy, :string # Strings with leading zeros
    change_column :death_data, :dodmt, :string # Strings with leading zeros
    # change_column :death_data, :agec, :string # Strings with leading zeros
    change_column :death_data, :ctrypob, :string # Strings with leading zeros
    change_column :death_data, :ctryr, :string # Strings with leading zeros
    change_column :death_data, :ctydr, :string # Alphanumeric
    change_column :death_data, :ctyr, :string # Strings with leading zeros
    change_column :death_data, :marstat, :string # Alphanumeric
    # change_column :death_data, :dobdy, :string # Strings with leading zeros
    # change_column :death_data, :dobmt, :string # Strings with leading zeros
    # change_column :death_data, :agecs, :string # Strings with leading zeros
  end

  def down
  end
end
