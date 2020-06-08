class MigrateOdrNcrasDatasetType < ActiveRecord::Migration[6.0]
  def up
    Dataset.reset_column_information

    datasets.each do |dataset|
      present_in_db = Dataset.find_by(name: dataset).presence
      next unless present_in_db

      present_in_db.update_attribute(:dataset_type, DatasetType.find_by(name: 'Linked'))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def datasets
    ['Cancer Registry', 'Linked HES IP', 'Linked HES OP', 'Linked HES A&E']
  end
end
