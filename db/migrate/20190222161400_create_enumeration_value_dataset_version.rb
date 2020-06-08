class CreateEnumerationValueDatasetVersion < ActiveRecord::Migration[5.2]
  def change
    create_table :enumeration_value_dataset_versions do |t|
      ix = 'index_ev_dataset_versions_on_enumeration_value_id'
      t.references :enumeration_value, foreign_key: true, index: { name: ix } 
      t.references :dataset_version, foreign_key: true

      t.timestamps
    end
  end
end
