class AddPublishedToDatasetVersion < ActiveRecord::Migration[6.0]
  def change
    add_column :dataset_versions, :published, :boolean, default: false
  end
end
