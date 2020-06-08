class AddTsCsAcceptedToProjectEndUser < ActiveRecord::Migration[5.0]
  def change
    add_column :project_data_end_users, :ts_cs_accepted, :boolean
  end
end
