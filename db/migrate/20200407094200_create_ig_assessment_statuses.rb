class CreateIgAssessmentStatuses < ActiveRecord::Migration[6.0]
  def change
    create_table :ig_assessment_statuses do |t|
      t.string :value, null: false

      t.timestamps
    end
  end
end
