class AddCloneOfToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :clone_of, :integer
  end
end
