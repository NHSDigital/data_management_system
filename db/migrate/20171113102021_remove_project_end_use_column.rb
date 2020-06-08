class RemoveProjectEndUseColumn < ActiveRecord::Migration[5.0]
  def change
    remove_column :projects, :end_use, :string
  end
end
