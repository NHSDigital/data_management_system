class PopulateOdrDataAssetsV8 < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    fname = 'datasets/NCRAS_ODR_data_dictionary_v8.0_KL.xlsx'
    o = OdrNcrasDataAssetImporter.new('8.0', fname, 'odr')
    o.build_data_assets
  end

  def down
    return if Rails.env.test?

    datasets.each do |dataset_name|
      ds = Dataset.find_by(name: dataset_name, dataset_type_id: DatasetType.find_by(name: 'odr').id)
      ds.dataset_versions.find_by(semver_version: '8.0').destroy
    end
  end

  def datasets
    [
      'Cancer registry',
      'SACT',
      'Linked RTDS',
      'Linked HES OP',
      'Linked HES A&E',
      'Linked DIDs',
      'NCDA',
      'LUCADA',
      'NLCA',
      'CPES Wave 1',
      'CPES Wave 2',
      'CPES Wave 3',
      'CPES Wave 4',
      'CPES Wave 5',
      'CPES Wave 6',
      'CPES Wave 7',
      'CPES Wave 8',
      'PROMs pilot 2011-2012',
      'PROMs - colorectal 2013',
      'Linked HES Admitted Care (IP)',
      'Linked CWT (treatments only)'
    ]
  end
end
