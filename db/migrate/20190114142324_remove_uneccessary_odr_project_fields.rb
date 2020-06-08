class RemoveUneccessaryOdrProjectFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :projects, :organisation_id
    remove_column :projects, :data_end_use_other
  end
end
