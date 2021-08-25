class AddReferentReferenceToDpias < ActiveRecord::Migration[6.0]
  def change
    add_column :data_privacy_impact_assessments, :referent_reference, :string
  end
end
