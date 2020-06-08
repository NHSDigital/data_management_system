class PublishMbisDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    mbis_datasets.each do |dataset, versions|
      next unless Dataset.for_browsing.find_by(name: dataset).present?

      Dataset.for_browsing.find_by(name: dataset).dataset_versions.each do |dataset_version|
        next unless versions.include? dataset_version.semver_version

        dataset_version.update_attribute(:published, true)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def mbis_datasets
    {
      'Births Gold Standard' => ['1-0'],
      'Death Transaction' => ['1-0'],
      'Deaths Gold Standard' => ['1-0'],
      'Birth Transaction' => ['1-0']
    }
  end
end
