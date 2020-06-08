class UnpublishNcrasDatasets < ActiveRecord::Migration[6.0]
  def up
    DatasetVersion.reset_column_information
    datasets.each do |dataset, versions|
      present_in_db = Dataset.find_by(name: dataset).presence
      next unless present_in_db

      versions.each do |version|
        version_present_in_db =
          present_in_db.dataset_versions.find_by(semver_version: version).presence
        next unless version_present_in_db

        version_present_in_db.update_attribute(:published, false)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def datasets
    {
      'Cancer Registry' => ['4-0'],
      'Linked HES IP' => ['4-0'],
      'Linked HES OP' => ['4-0'],
      'Linked HES A&E' => ['4-0']
    }
  end
end
