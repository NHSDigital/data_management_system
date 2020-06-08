class PopulateDatasetViewerAnalystSystemRole < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup SystemRole, 6, sort: 6, name: 'Dataset Viewer Analyst'
  end
end
