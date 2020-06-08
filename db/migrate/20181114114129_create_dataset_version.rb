class CreateDatasetVersion < ActiveRecord::Migration[5.2]
  def change
    create_table :dataset_versions do |t|
      t.integer :dataset_id
      t.string :semver_version

      t.timestamps
    end
  end
end
