class AddUniquenessConstraints < ActiveRecord::Migration[5.0]
  def change
    add_index :z_user_statuses, :name, unique: true
    add_index :z_team_statuses, :name, unique: true
    add_index :z_project_statuses, :name, unique: true
    add_index :data_sources, :name, unique: true
    add_index :data_source_items, [:name, :data_source_id], unique: true
    add_index :notification_templates, :name, unique: true
  end
end
