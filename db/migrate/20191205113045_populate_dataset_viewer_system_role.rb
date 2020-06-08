class PopulateDatasetViewerSystemRole < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup SystemRole, 5, sort: 5, name: 'Dataset Viewer'
  end
end
