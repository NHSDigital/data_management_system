class FixBirthDataRemoveIdentifiableFields2 < ActiveRecord::Migration[5.0]
  def change
    remove_column :birth_data, :ledrid, :string
    remove_column :birth_data, :mbism204id, :string
  end
end
