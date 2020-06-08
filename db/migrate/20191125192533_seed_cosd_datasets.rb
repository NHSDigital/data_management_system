class SeedCosdDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if Dataset.where(name: 'COSD').count.positive? # already manually seeded
    Dataset.reset_column_information
    
    Rake::Task['xsd:seed'].invoke
    Rake::Task['xsd:previous_node_ids'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
