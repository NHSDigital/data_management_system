class AddStatusToTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :status, :boolean
  end
end
