class AlterReferentNullabilityOnContracts < ActiveRecord::Migration[6.0]
  def change
    change_column_null :contracts, :referent_type, false
    change_column_null :contracts, :referent_id,   false
  end
end
