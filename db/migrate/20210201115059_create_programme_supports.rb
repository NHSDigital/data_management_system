# plan.io 22212
# Create ProgrammeSupports lookup table
class CreateProgrammeSupports < ActiveRecord::Migration[6.0]
  def change
    create_table :programme_supports do |t|
      t.string :value
      t.timestamps
    end
  end
end
