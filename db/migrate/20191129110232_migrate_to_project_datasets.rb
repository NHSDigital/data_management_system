class MigrateToProjectDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if ProjectDataset.count.positive?
    
    Rake::Task['project_dataset:migrate'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
