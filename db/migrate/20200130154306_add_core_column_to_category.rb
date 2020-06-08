class AddCoreColumnToCategory < ActiveRecord::Migration[6.0]
  def change
    add_column :categories, :core,  :boolean
  end
end
