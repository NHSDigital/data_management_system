class ReupdatePopulatedDatasets < ActiveRecord::Migration[6.0]
  def up
    datasets.each do |dataset_type, datasets|
      datasets.each do |dataset|
        present_in_db = Dataset.find_by(name: dataset).presence
        next unless present_in_db

        present_in_db.update_attribute(:dataset_type_id, DatasetType.find_by(name: dataset_type).id)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def datasets
    {
      'XML Schema' => ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard',
                       'Birth Transaction', 'Cancer Registry', 'Linked HES IP', 'Linked HES OP',
                       'Linked HES A&E', 'SACT', 'CAS'],
      'Non XML Schema' => ['COSD', 'COSD_Pathology', 'MultipleRecordTypeDataset']
    }
  end
end
