class RemoveRedundantDepartmentColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :projects, :sponsor_department, :string
    remove_column :projects, :funder_department, :string
    remove_column :projects, :data_processor_department, :string
  end
end
