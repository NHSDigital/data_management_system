# Import Datascience spreadsheert
class DataScienceImporter
  require 'ndr_import/helpers/file/excel'
  include NdrImport::Helpers::File::Excel

  attr_accessor :semver, :excel_file,
                :dataset_version, :version_entity

  def initialize(semver, fname)
    @semver = semver
    @excel_file = excel_tables(SafePath.new('db_files').join(fname))
  end

  # Load worksheets and link them together
  def build
    before_count = Dataset.count
    Dataset.transaction do
      @excel_file.each do |worksheet_name, worksheet|
        build_table_details(worksheet) if worksheet_name == 'tTableDetails'
        build_table_columns(worksheet) if worksheet_name == 'tTableColumns'
      end
      collate
      build_nodes
    end
    print "Created #{Dataset.count - before_count} Dataset(s)\n"
  end

  def build_nodes
    Dataset.transaction do
      @dataset = Dataset.create!(name: @server_name, team: Team.find_by(name: 'Data Lake'),
                                 dataset_type_id: DatasetType.fetch(:table_spec).id)
      @dataset_version = DatasetVersion.create!(dataset: @dataset, semver_version: semver,
                                                published: true)
      @server_node = Nodes::Entity.new(occurrences.merge(name: @dataset.name,
                                                         dataset_version: @dataset_version))
      build_tables
    end
  end

  def build_tables
    @datascience.each.with_index(1) do |(database_name, tables), db_sort|
      next unless current_dbs_to_build.include? database_name

      database_node_attrs = occurrences.merge(name: database_name, sort: db_sort,
                                              dataset_version_id: @dataset_version.id)
      database_node = Nodes::Database.new(database_node_attrs)

      tables.each.with_index(1) do |(table_id, table_metadata), tb_sort|
        next unless current_tables.include? table_metadata[:details]['qualified_table_name']

        database_node.child_nodes << build_table_node(table_id, table_metadata, tb_sort)
      end

      @server_node.child_nodes << database_node
    end

    @server_node.save!
  end

  def build_table_node(table_id, metadata, sort)
    table_node_attrs =
      occurrences.merge(table_id: table_id, dataset_version_id: @dataset_version.id, sort: sort)
    table_node = Nodes::Table.new(table_node_attrs)
    assign_attributes(table_node, metadata[:details])
    # some tables appear to have noo columns in spreadsheet
    return table_node if metadata[:columns].nil?

    metadata[:columns].each do |column_id, column_metadata|
      column_node_attrs =
        occurrences.merge(column_id: column_id, dataset_version_id: @dataset_version.id)
      column_node = Nodes::DataItem.new(column_node_attrs)
      assign_attributes(column_node, column_metadata)
      table_node.child_nodes << column_node
    end

    table_node
  end

  def assign_attributes(node, hash_values)
    hash_values.each do |attribute, val|
      next if node.attributes.keys.exclude? attribute

      # kludge table_name as name so existing views work
      node.send('name=', val) if attribute == 'table_name'
      # kludge field_name as name so existing views work
      node.send('name=', val) if attribute == 'field_name'
      node.send("#{attribute}=", val)
    end
  end

  def details_attrs
    %w[table_name table_schema_name qualified_table_name table_type
       table_type_description create_date	modify_date number_of_columns primary_key_name
       primary_key_columns table_description table_comment published removed ]
  end

  def column_attrs
    %w[column_id table_id field_number field_name field_type allow_nulls
       hes_field_name field_description validation_rules]
  end

  def build_table_details(worksheet)
    @datascience = {}
    worksheet.each_with_index do |row, i|
      next if i.zero?

      table_id = row.shift
      server_name(row.shift)
      database_name = row.shift
      details = details_attrs.zip(row).to_h
      @datascience[database_name] ||= {}
      @datascience[database_name][table_id] = { details: clean_hash!(details) }
    end
  end

  def build_table_columns(worksheet)
    @columns = {}
    worksheet.each_with_index do |row, i|
      next if i.zero?

      details = column_attrs.zip(row).to_h
      table_id = details.delete('table_id')
      column_id = details.delete('column_id')
      @columns[table_id] ||= {}
      @columns[table_id].merge!(column_id => clean_hash!(details))
    end
  end

  def clean_hash!(hash)
    hash.transform_values { |val| val == 'NULL' ? nil : val }
  end

  def collate
    @datascience.each do |_database_name, database_details|
      database_details.each do |table_id, table_details|
        table_details[:columns] = @columns[table_id]
      end
    end
  end

  private

  # Spreadsheet has everything
  def current_dbs_to_build
    %w[HES_AE HES_APC HES_Outpatient HES_PID_AE HES_PID_APC HES_PID_Outpatient BirthsDeaths
       HES_Linked_ONS_Mort LookupsShared]
  end

  def current_tables
    current_birthsdates_tables + current_linked_mortality_tables +
      current_hes_tables + current_lookup_tables
  end

  def current_birthsdates_tables
    %w[dbo.Comcodes dbo.vBirthsALL dbo.vBirthsALL_NSPL_2017-05 dbo.vComcodes
       dbo.vDeathsALL dbo.vDeathsALL_NSPL_2017-05 dbo.vDeathsALL_NSPL_2017-05_AAF(revised)]
  end

  def current_linked_mortality_tables
    %w[dbo.PHE_HES_LinkedONS dbo.PHE_HES_LinkedONS_Archive dbo.tExtractLog dbo.vtHES_LinkedONS]
  end

  def current_hes_tables
    %w[dbo.vDataValidationLog dbo.vHES_AE_SAV dbo.vtHES_AE dbo.vtHES_AE_DIAG dbo.vtHES_AE_INVEST
       dbo.vtHES_AE_TREAT dbo.vHES_APC_DIAG_Flat dbo.vHES_APC_Flat dbo.vHES_APC_OPERTN_Flat
       dbo.vHES_APC_SAV dbo.vtHES_APC dbo.vtHES_APC_CC dbo.vtHES_APC_DIAG dbo.vtHES_APC_MAT
       dbo.vtHES_APC_OPERTN dbo.vHES_OP_SAV dbo.vtHES_OP dbo.vtHES_OP_DIAG dbo.vtHES_OP_OPERTN
       dbo.vtHES_PID_AE dbo.vHES_PID_APC_Flat dbo.vtHES_PID_APC dbo.vtHES_PID_OP]
  end

  def current_lookup_tables
    %w[dbo.vClinical_ICD10 dbo.vClinical_ICD10_Chapters dbo.vLKP_CCG15 dbo.vLKP_CCG16
       dbo.vLKP_CCG17 dbo.vLKP_CCGApr18 dbo.vLKP_EER09 dbo.vLKP_LSOA11 dbo.vLKP_LTLA13
       dbo.vLKP_LTLA13_HistoricCodes dbo.vLKP_MSOA11 dbo.vLKP_NHSRLO17 dbo.vLKP_NHSRLOApr18
       dbo.vLKP_OA11 dbo.vLKP_PCON10 dbo.vLKP_PHEC15 dbo.vLKP_RGC_Entities dbo.vLKP_RGC_Instances
       dbo.vLKP_RGN09 dbo.vLKP_STP17 dbo.vLKP_STPApr18 dbo.vLKP_UTLA13 dbo.vLKP_WD16 dbo.vLKP_WD17
       dbo.vLKPBestFit_LSOA11 dbo.vONS_NSPL_UK dbo.vONS_NSPL_UK_Date dbo.vRef_ESP2013
       dbo.vSocioDemog_LSOA11 dbo.vSocioDemog_LTLA13 dbo.vSocioDemog_UTLA13 ]
  end

  def server_name(name)
    @server_name ||= name
  end

  def occurrences
    { min_occurs: 1, max_occurs: 1 }
  end
end
