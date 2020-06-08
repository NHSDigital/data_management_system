class RenameProjectIgToolkitFields < ActiveRecord::Migration[5.2]
  def change
    rename_column :projects, :ig_tooklit_version, :ig_toolkit_version
    rename_column :projects, :ig_tooklit_version_outsourced, :ig_toolkit_version_outsourced
  end
end
