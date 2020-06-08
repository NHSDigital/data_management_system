# Beta and live appear to be missing dataset_type for the old style mbis data sources
class UpdateLegacyMbisDatasets < ActiveRecord::Migration[6.0]
  def up
    Dataset.where(name: mbis_datasets).each do |dataset|
      next unless dataset.dataset_type_id.nil?

      dataset.update_attribute(:dataset_type_id, DatasetType.find_by(name: 'non_xml').id)
    end
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def mbis_datasets
    ['Birth Transaction', 'Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard']
  end
end
