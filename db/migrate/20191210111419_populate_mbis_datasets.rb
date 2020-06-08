# Populate MBIS Datasets or whatever we are calling them if migrating from scratch
class PopulateMbisDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    mbis_datasets.each do |dataset_name, version|
      present_in_db = Dataset.find_by(name: dataset_name).present?
      next if present_in_db

      dataset = Dataset.create!(name: dataset_name, team: Team.find_by(name: 'ODR'),
                                dataset_type: DatasetType.find_by(name: 'non_xml'))
      dataset_version = DatasetVersion.create!(dataset: dataset,
                                               semver_version: version,
                                               published: true)
      version_entity = Nodes::Entity.new(occurrences.merge(name: dataset_name,
                                                           dataset_version: dataset_version))
      nodes = YAML.load_file(SafePath.new('db_files').join("#{dataset_name.split.join}.yml"))
      nodes.each do |node_attrs|
        build_node(version_entity, node_attrs, dataset_version)
      end

      version_entity.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def mbis_datasets
    {
      'Births Gold Standard' => '1-0',
      'Death Transaction' => '1-0',
      'Deaths Gold Standard' => '1-0',
      'Birth Transaction' => '1-0'
    }
  end

  def occurrences
    { min_occurs: 0, max_occurs: 1 }
  end

  def build_node(node, node_attrs, dataset_version)
    klass = node_attrs.delete('node_type').constantize
    children = node_attrs.delete('children')
    governance = node_attrs.delete('governance')
    new_node = klass.new(node_attrs)
    new_node.dataset_version = dataset_version
    new_node.governance = Governance.find_by(value: governance) if governance
    children&.each { |child_attrs| build_node(new_node, child_attrs, dataset_version) }

    node.child_nodes << new_node
  end
end
