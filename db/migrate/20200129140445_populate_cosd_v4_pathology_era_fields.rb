class PopulateCosdV4PathologyEraFields < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if dataset_version.nil?

    filepath = 'lib/tasks/xsd/PathologyV4.yml'
    v9 = EraFieldsUpdater.new(dataset_version, filepath)
    v9.build
  end
  
  def down
    return if Rails.env.test?
    return if dataset_version.nil?

    counter = 0
    dataset_version.nodes.each do |node|
      next if node.era_fields.nil?
      
      node.era_fields.destroy!
      counter += 1
    end
    
    print "\n Destroyed #{counter} era_fields!\n"
  end

  def dataset_version
    dataset = Dataset.find_by(name: 'COSD_Pathology')
    @dataset ||= dataset.dataset_versions.find_by(semver_version: '4-1-1')
  end
end
