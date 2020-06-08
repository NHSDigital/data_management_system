class CreateIdentifiabilityLevels < ActiveRecord::Migration[5.2]
  def change
    create_table :identifiability_levels do |t|
      t.string :value
      t.timestamps
    end
  end
end
