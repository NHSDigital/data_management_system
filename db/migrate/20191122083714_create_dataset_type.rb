class CreateDatasetType < ActiveRecord::Migration[6.0]
  def change
    create_table :dataset_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
