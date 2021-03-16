# Add missing ODR COVID 19 dataset
class PopulateOdrCovid19Dataset < ActiveRecord::Migration[6.0]
  def up
    Dataset.new(dataset_options).tap do |dataset|
      dataset.dataset_versions.build(semver_version: '1.0', published: false)

      dataset.save!
    end
  end

  def down
    Dataset.odr.find_by(name: 'COVID 19').destroy
  end

  def dataset_options
    {
      name: 'COVID 19',
      dataset_type: DatasetType.find_by(name: 'odr'),
      team: Organisation.find_by(name: 'Public Health England').teams.find_by(name: 'NCRAS')
    }
  end
end
