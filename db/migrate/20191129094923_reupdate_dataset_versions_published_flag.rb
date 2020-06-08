class ReupdateDatasetVersionsPublishedFlag < ActiveRecord::Migration[6.0]
  def up
    DatasetVersion.reset_column_information

    dataset_versions.each do |published, datasets|
      datasets.each do |dataset, versions|
        present_in_db = Dataset.find_by(name: dataset).presence
        next unless present_in_db

        versions.each do |version|
          version_present_in_db =
            present_in_db.dataset_versions.find_by(semver_version: version).presence
          next unless version_present_in_db

          version_present_in_db.update_attribute(:published, published)
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def dataset_versions
    {
      true => {
        'Births Gold Standard' => ['1-0'],
        'Death Transaction' => ['1-0'],
        'Deaths Gold Standard' => ['1-0'],
        'Birth Transaction' => ['1-0'],
        'Cancer Registry' => ['4-0'],
        'Linked HES IP' => ['4-0'],
        'Linked HES OP' => ['4-0'],
        'Linked HES A&E' => ['4-0'],
        'COSD' => ['8-1', '9-0'],
        'COSD_Pathology' => ['3-0', '4-1'],
      },
      false => {
        'CAS' => ['1-0'],
        'SACT' => ['2-0'],
        'MultipleRecordTypeDataset' => ['1-0'],
        'COSD' => ['8-2', '8-3'],
        'COSD_Pathology' => ['3-1']
      }
    }
  end
end
