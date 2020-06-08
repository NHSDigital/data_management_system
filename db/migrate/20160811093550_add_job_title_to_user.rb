class AddJobTitleToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :job_title, :string
  end
end
