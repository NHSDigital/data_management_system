class CreateProcessingTerritories < ActiveRecord::Migration[5.2]
  def change
    create_table :processing_territories do |t|
      t.string :value
      t.timestamps
    end
  end
end
