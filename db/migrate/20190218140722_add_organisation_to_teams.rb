class AddOrganisationToTeams < ActiveRecord::Migration[5.2]
  def change
    add_reference :teams, :organisation, foreign_key: true
  end
end
