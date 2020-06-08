# Refresh EraFields
class UpdateCosdV9EraFields < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    unless cosd_v9.nil?
      EraFields.delete_all
      filepath = 'lib/tasks/xsd/V9.yml'
      v9 = EraFieldsUpdater.new(cosd_v9, filepath)
      v9.build
    end

    unless path_v4.nil?
      filepath = 'lib/tasks/xsd/PathologyV4.yml'
      v4 = EraFieldsUpdater.new(path_v4, filepath)
      v4.build
    end

    e = EraFieldsUpdater.new(DatasetVersion.first, 'lib/tasks/xsd/FKs.yml')
    e.seed_fk_tables
  end

  def down
    return if Rails.env.test?

    EraFields.delete_all
  end

  def cosd_v9
    dataset = Dataset.find_by(name: 'COSD')
    @cosd_v9 ||= dataset.dataset_versions.find_by(semver_version: '9.0')
  end

  def path_v4
    dataset = Dataset.find_by(name: 'COSD_Pathology')
    @path_v4 ||= dataset.dataset_versions.find_by(semver_version: '4.1.1')
  end
end
