# Used to import a cleaned up version of the Analysts NCRAS_ODR_data_dictionary.xlsx file
# ODR can't agree with NCRAS on Dataset names or Data Items.
# For now we could just have a placeholder dataset so EOI's work
# We could just let them build the items in the dataset when/if they ever agree.
# Most datasets are flat. i.e sections and items and no nested sections.
class OdrNcrasDataAssetImporter
  require 'ndr_import/helpers/file/excel'
  include NdrImport::Helpers::File::Excel

  attr_accessor :semver, :excel_file, :dataset_type,
                :dataset_version, :version_entity

  def initialize(semver, fname, dataset_type = nil)
    @semver = semver
    @excel_file = excel_tables(SafePath.new('db_files').join(fname))
    @dataset_type = dataset_type
  end

  def build_data_assets
    results = []
    # before_count = Dataset.count
    # group_count = Nodes::Group.count
    # item_count = Nodes::DataItem.count
    # entity_count = Nodes::Entity.count
    Dataset.transaction do
      @excel_file.each do |dataset_name, worksheet|
        build_data_asset(dataset_name)
        build(worksheet)
        results << { @dataset_version.name => @version_entity.child_nodes.length }

        @version_entity.save!
      end
    end
    # print '*' * 10
    # print JSON.pretty_generate(results)
    # print '*' * 10
    # print "Group diff - #{Nodes::Group.count - group_count}"
    # print "DataItem diff - #{Nodes::DataItem.count - item_count}"
    # print "Entity diff - #{Nodes::Entity.count - entity_count}"
    # print "Created #{Dataset.count - before_count} Dataset(s)"
  end

  def build_data_asset(dataset_name)
    dataset = Dataset.find_or_initialize_by(name: dataset_name, full_name: dataset_name,
                                            team: Team.find_by(name: 'NCRAS'))
    dataset.dataset_type = DatasetType.find_by(name: dataset_type) if dataset_type
    # Get around Dataset Types being thing after
    # 20191115134127_add_odr_ncras_datasets_cancer_registry_and_hesv4
    dataset.save!(validate: false)

    @dataset_version = DatasetVersion.create!(dataset: dataset, semver_version: semver,
                                              published: true)
    @version_entity = Nodes::Entity.new(occurrences.merge(name: dataset_name,
                                                          dataset_version: @dataset_version))
  end

  def build(worksheet)
    @group_sort = 1
    @item_sort = 1
    worksheet.each_with_index do |row, i|
      @header = row if i.zero?
      next if i.zero?

      if row.compact.length == 1
        @group = build_group(row.first)
      else
        node_attrs = @header.zip(row).to_h
        node_attrs.transform_keys! { |node_attr| header_mapping[node_attr.downcase] }
        node_attrs['sort'] = @item_sort
        item = Nodes::DataItem.new(occurrences.merge(node_attrs.except(*ignored_fields)))
        item.dataset_version = @dataset_version
        gov = node_attrs['governance'] == '1' ? 'DIRECT IDENTIFIER' : 'NON IDENTIFYING DATA'
        item.governance = Governance.find_by(value: gov)
        @group.child_nodes << item
        @item_sort += 1
      end
    end
  end

  def build_group(name)
    @item_sort = 1
    name = ActionView::Base.full_sanitizer.sanitize(name)
    group = Nodes::Group.new(occurrences.merge(name: name,
                                               sort: @group_sort,
                                               dataset_version: @dataset_version))
    @group_sort += 1
    @version_entity.child_nodes << group
    group
  end

  def wipe_previous_version
    datasets.each do |dataset_name|
      ds = Dataset.find_by(name: dataset_name, dataset_type_id: DatasetType.find_by(name: 'odr').id)
      next if ds.nil?

      dv = ds.dataset_versions.find_by(semver_version: semver)
      next if dv.nil?

      dv.destroy
    end
  end

  private

  # NCRAS field name, Node field name
  def header_mapping
    res = 'restrictions and advice on selecting variables with the highest data quality'
    {
      'data item'                        => 'annotation',
      'field name'                       => 'name',
      'description of field content'     => 'description',
      'description'                      => 'description',
      'variable type'                    => 'field_type',
      res                                => 'restrictions_recommendations',
      'restrictions and recommendations' => 'restrictions_recommendations',
      'notes'                            => 'notes',
      'governance'                       => 'governance',
      'derived'                          => 'derived',
      'reference'                        => 'reference'
    }
  end

  def ignored_fields
    %w[governance]
  end

  def node_fields
    %w[annotation name description field_type restrictions_recommendations notes derived]
  end

  def occurrences
    { min_occurs: 0, max_occurs: 1 }
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
