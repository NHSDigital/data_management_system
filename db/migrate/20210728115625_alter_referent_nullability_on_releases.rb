class AlterReferentNullabilityOnReleases < ActiveRecord::Migration[6.0]
  def change
    change_column_null :releases, :referent_type, false
    change_column_null :releases, :referent_id,   false
  end
end
