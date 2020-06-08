class CreateDataPrivacyImpactAssessments < ActiveRecord::Migration[6.0]
  def change
    create_table :data_privacy_impact_assessments do |t|
      t.references :project,              foreign_key: true
      t.references :project_state,        foreign_key: { to_table: :workflow_project_states }
      t.string     :ig_toolkit_version
      t.integer    :ig_score
      t.references :ig_assessment_status, foreign_key: true, index: { name: 'index_dpias_on_ig_assessment_status_id' }
      t.datetime   :review_meeting_date
      t.datetime   :dpia_decision_date

      t.timestamps
    end
  end
end
