# Create access_levels lookup table
class CreateAccessLevels < ActiveRecord::Migration[6.0]
  def change
    create_table :access_levels do |t|
      t.string :value
      t.string :description

      t.timestamps
    end
  end
end
