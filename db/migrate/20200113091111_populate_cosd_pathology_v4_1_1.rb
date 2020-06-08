# Seed new COSD_Pathology version if it doesn't exist
class PopulateCosdPathologyV411 < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return unless dataset_version.nil?

    dv = DatasetVersion.create!(dataset: @dataset, semver_version: '4-1-1')
      
    Rake::Task['xsd:path_4_1_1_categories'].invoke
    Rake::Task['xsd:path_4_1_1_nodes'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
  
  def dataset_version
    @dataset = Dataset.find_by(name: 'COSD_Pathology')
    @dataset.dataset_versions.find_by(semver_version: '4-1-1')
  end


  def categories
    fname = Rails.root.join('lib', 'tasks', 'xsd', 'categories.yml')
    Category.transaction do
      YAML.safe_load(File.open(fname), [Symbol]).each_value do |row|
        ignored_fields = %w[dataset_name dataset_version]
        e = Category.new(row.except(*ignored_fields))
        e.dataset_version = version_for_dataset(row['dataset_name'], row['dataset_version'])
        e.save!
      end
    end
  end
end
