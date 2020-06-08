class UpdateTeamForMbisNonXmlDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    team = Team.find_by(name: 'MBIS')
    scope = Dataset.where(dataset_type_id:  DatasetType.find_by(name: 'non_xml'))
    scope = scope.where(name: mbis_datasets)
    scope.update_all(team_id: team.id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def mbis_datasets
    ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard', 'Birth Transaction']
  end
end
