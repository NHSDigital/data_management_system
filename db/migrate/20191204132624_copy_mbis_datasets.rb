# Create a copy of MBIS datasets for dataset browsing
class CopyMbisDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    Dataset.transaction do
      Dataset.where(name: mbis_datasets).each do |dataset|
        linked_dataset = Dataset.new(dataset.attributes.except(*ignored_dataset_fields))
        linked_dataset.dataset_type = DatasetType.find_by(name: 'Linked')
        linked_dataset.save!

        dataset.dataset_versions.each do |dataset_version|
          version = DatasetVersion.create!(semver_version: dataset_version.semver_version,
                                           dataset: linked_dataset, published: true)
          new_version_entity =
            Nodes::Entity.new(dataset_version: version, name: dataset.name, sort: 0,
                              description: dataset.description, min_occurs: 1, max_occurs: 1)

          dataset_version.version_entity.child_nodes.each do |child_node|
            dataset_version.build_child(new_version_entity, child_node, version)
          end
          new_version_entity.save!
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def ignored_dataset_fields
    %w[id created_at updated_at dataset_type_id]
  end

  def mbis_datasets
    ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard', 'Birth Transaction']
  end

  def create_child_nodes(version, category, items, parent_node, sort)
    entity = Nodes::Entity.create!(name: category, min_occurs: 0, sort: sort,
                                   max_occurs: 1, dataset_version: version)
    items.each_with_index do |item, i|
      n = Nodes::DataItem.new(dataset_version: version, name: item.name,
                              description: item.description, min_occurs: item.occurrences,
                              max_occurs: item.occurrences, sort: i)
      n.governance = Governance.find_by(value: item.governance)
      entity.child_nodes << n
    end
    parent_node.child_nodes << entity
  end
end
