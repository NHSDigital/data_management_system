class AlterReferentNullabilityOnDpias < ActiveRecord::Migration[6.0]
  def change
    change_column_null :data_privacy_impact_assessments, :referent_type, false
    change_column_null :data_privacy_impact_assessments, :referent_id,   false
  end
end
