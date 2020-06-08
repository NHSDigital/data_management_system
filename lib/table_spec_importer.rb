# Used to import a cleaned up version of the Analysts NCRAS_ODR_data_dictionary.xlsx file
# ODR can't agree with NCRAS on Dataset names or Data Items.
# For now we could just have a placeholder dataset so EOI's work
# We could just let them build the items in the dataset when/if they ever agree.
# Most datasets are flat. i.e sections and items and no nested sections.
class TableSpecImporter
  require 'ndr_import/helpers/file/excel'
  include NdrImport::Helpers::File::Excel

  attr_accessor :semver, :excel_file, :dataset_type, :dataset_name,
                :dataset_version, :version_entity, :team, :rows

  def initialize(semver, fname, team_name, dataset_name, dataset_type = nil)
    @semver = semver
    @excel_file = excel_tables(SafePath.new('db_files').join(fname))
    @team = Team.find_by(name: team_name)
    @dataset_type = dataset_type
    @dataset_name = dataset_name
    raise 'No Team exists' if team.nil?
  end

  def build
    Dataset.transaction do
      build_dataset(dataset_name)
      # TODO:Database node is just dataset node
      database_node = Nodes::Database.new(occurrences.merge(name: dataset_name,
                                                            dataset_version: @dataset_version))
      @excel_file.each.with_index(1) do |(table_name, worksheet), i|
        table_node = build_table_node(table_name, i)
        load_rows(worksheet)
        sort_rows_and_build_nodes(table_node)
        database_node.child_nodes << table_node
      end
      @version_entity.child_nodes << database_node
      @version_entity.save!
    end
  end

  def build_dataset(dataset_name)
    dataset = Dataset.find_or_initialize_by(name: dataset_name, full_name: dataset_name, team: team)
    dataset.dataset_type = DatasetType.find_by(name: dataset_type)
    dataset.save!

    @dataset_version = DatasetVersion.create!(dataset: dataset, semver_version: semver,
                                              published: true)
    @version_entity = Nodes::Entity.new(occurrences.merge(name: dataset_name,
                                                          dataset_version: @dataset_version))
  end

  def build_table_node(table_name, sort)
    table_node_attrs =
      occurrences.merge(name: table_name, dataset_version_id: @dataset_version.id, sort: sort)
    Nodes::Table.new(table_node_attrs)
  end

  def load_rows(worksheet)
    @group_sort = 1
    @item_sort = 1
    @rows = []
    worksheet.each_with_index do |row, i|
      @header = row if i.zero?
      next if i.zero?

      @rows << @header.zip(row).to_h
    end
  end

  def sort_rows_and_build_nodes(table_node)
    grouped_by_node_type = rows.group_by { |row| row['parent_node'] }
    build_children(table_node, sort = 0)
  end

  def build_children(node, sort)
    @rows.find_all { |row| row['parent_node'] == node.name }.each do |row|
      row['sort'] = sort
      build_node(node, row)
      sort += 1
    end
  end
  
  def build_node(parent, attrs)
    governance = attrs.delete('governance')
    node_type = attrs.delete('node_type')
    parent_node = attrs.delete('parent_node')
    node = node_type.constantize.new(occurrences.merge(attrs))
    node.dataset_version = @dataset_version
    node.governance = Governance.find_by(value: governance)
    build_children(node, sort = 1)
    parent.child_nodes << node
  end

  private

  def occurrences
    { min_occurs: 0, max_occurs: 1 }
  end
end
