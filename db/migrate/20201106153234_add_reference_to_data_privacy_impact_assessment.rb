class AddReferenceToDataPrivacyImpactAssessment < ActiveRecord::Migration[6.0]
  def change
    add_column :data_privacy_impact_assessments, :reference, :string
  end
end
