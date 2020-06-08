# Used to import a cleaned up version of the Analysts NCRAS_ODR_data_dictionary.xlsx file
# ODR can't agree with NCRAS on Dataset names or Data Items.
# For now we could just have a placeholder dataset so EOI's work
# We could just let them build the items in the dataset when/if they ever agree.
# Most datasets are flat. i.e sections and items and no nested sections.
class OdrNcrasDatasetImporter
  require 'ndr_import/helpers/file/excel'
  include NdrImport::Helpers::File::Excel

  attr_accessor :semver, :excel_file,
                :dataset_version, :version_entity

  def initialize(semver, fname)
    @semver = semver
    @excel_file = excel_tables(SafePath.new('db_files').join(fname))
    # @excel_file = read_excel_file(SafePath.new('db_files').join(fname))
  end

  def build_datasets
    before_count = Dataset.count
    Dataset.transaction do
      @excel_file.each do |dataset_name, worksheet|
        build_dataset(dataset_name)
        build_entities(worksheet)
        build_data_items(worksheet)
      end
    end
    print "Created #{Dataset.count - before_count} Dataset(s)"
  end

  def build_dataset(dataset_name)
    dataset = Dataset.new(name: dataset_name, full_name: dataset_name)
    # Get around Dataset Types being thing after
    # 20191115134127_add_odr_ncras_datasets_cancer_registry_and_hesv4
    dataset.save!(validate: false)
    @dataset_version = DatasetVersion.create!(dataset: dataset, semver_version: semver)
    @version_entity =
      Nodes::Entity.create!(occurrences.merge(name: dataset_name,
                                              dataset_version: @dataset_version))
  end

  def build_entities(worksheet)
    sort = 1
    # Track entities already made
    entities = []
    worksheet.each_with_index do |row, i|
      next if i.zero?

      node_attrs = node_fields.zip(row).to_h
      next if entities.include? node_attrs['parent_node'] # already made

      record_entity = Nodes::Entity.new(occurrences.merge(name: node_attrs['parent_node'],
                                                          sort: i,
                                                          dataset_version: @dataset_version))
      @version_entity.child_nodes << record_entity
      entities.push node_attrs['parent_node']
      sort += 1
    end
    @version_entity.save!
  end

  def build_data_items(worksheet)
    @item_sort = 1
    entities = []
    worksheet.each_with_index do |row, i|
      next if i.zero?

      node_attrs = node_fields.zip(row).to_h
      @item_sort = 1 if entities.exclude? node_attrs['parent_node'] # reset for new entity
      node_attrs['sort'] = @item_sort
      item = Nodes::DataItem.new(occurrences.merge(node_attrs.except(*ignored_fields)))
      item.dataset_version = @dataset_version
      item.governance = Governance.find_by(value: node_attrs['governance'])
      item.parent_node = version_entity.child_nodes.find_by(name: node_attrs['parent_node'])

      item.save!
      entities.push node_attrs['parent_node']
      @item_sort += 1
    end
  end

  private

  # NCRAS field name, Node name
  # 'Data item' => 'description',
  # 'Field name' => 'name',
  # 'Description of field content' => 'description_detail',
  # 'Derived' => 'Derived',
  # "governance" => governance,
  # 'parent_node' => 'parent_node'

  def ignored_fields
    %w[governance parent_node]
  end

  def node_fields
    %w[description name description_detail derived governance parent_node]
  end

  def occurrences
    { min_occurs: 0, max_occurs: 1 }
  end
end
