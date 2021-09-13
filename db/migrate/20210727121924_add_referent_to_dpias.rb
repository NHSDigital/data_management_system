class AddReferentToDpias < ActiveRecord::Migration[6.0]
  def change
    add_reference :data_privacy_impact_assessments, :referent, polymorphic: true, index: { name: :index_dpias_on_referent_type_and_referent_id }
  end
end
