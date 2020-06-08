class UpdateTeamForOdrDataAssets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    team = Team.find_by(name: 'NCRAS')
    scope = Dataset.where(dataset_type_id:  DatasetType.find_by(name: 'odr'))
    scope = scope.where(name: ncras_datasets)
    scope.update_all(team_id: team.id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def ncras_datasets
    ['PROMs pilot 2011-2012', 'PROMs - colorectal 2013', 'Cancer registry', 'SACT', 'Linked RTDS',
     'Linked HES IP', 'Linked HES OP', 'Linked HES A&E', 'Linked CWT', 'Linked DIDs', 'NCDA',
     'CPES Wave 1', 'CPES Wave 2', 'CPES Wave 3', 'CPES Wave 4', 'CPES Wave 5', 'CPES Wave 6',
     'CPES Wave 7', 'CPES Wave 8', 'LUCADA']
  end
end
