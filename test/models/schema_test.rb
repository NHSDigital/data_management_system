require 'test_helper'
require 'ndr_import/helpers/file/xml'
require 'rake'
# To generate files for these tests
# bin/rake xsd:all
# set run_test: true in config/xsd.yml
class SchemaTest < ActiveSupport::TestCase
  include NdrImport::Helpers::File::Xml

  # A ephemeral subdirectory, to allow multiple processes to test at once.
  def self.tmp_subdir
    @tmp_subdir ||= SecureRandom.hex(16)
  end

  # Clean up once the tests are over:
  Minitest.after_run do
    directory = Rails.root.join('tmp', SchemaTest.tmp_subdir)
    FileUtils.rm_r(directory) if File.exist?(directory)
  end

  def setup
    @@already_built ||= nil
    return if @@already_built

    ensure_file_paths_exist(self.class.tmp_subdir)

    Nodes::Utility.stubs(schema_pack_location: tmp_location)

    build_schema_files
    @@already_built = true
  end

  test 'generated XSD is valid' do
    return unless RUN_SCHEMA_TESTS

    assert_nothing_raised do
      sact_two_zero       = tmp_location.join('schema', 'SACT-v2-0.xsd')
      pathology_three_one = tmp_location.join('schema', 'COSD_Pathology-v3-1.xsd')
      pathology_four_one  = tmp_location.join('schema', 'COSD_Pathology-v4-1.xsd')
      cosd_nine_zero      = tmp_location.join('schema', 'COSD-v9-0.xsd')

      Nokogiri::XML::Schema(File.open(sact_two_zero))
      Nokogiri::XML::Schema(File.open(pathology_three_one))
      Nokogiri::XML::Schema(File.open(pathology_four_one))
      Nokogiri::XML::Schema(File.open(cosd_nine_zero))
    end
  end

  test 'Hand crafted SACT Sample XML is valid' do
    return unless RUN_SCHEMA_TESTS

    filepath = SafePath.new('xml_files').join('SACT_SAMPLE.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'SACT')
    end
  end

  test 'Hand crafted COSD v9-0 Sample XML is valid' do
    return unless RUN_SCHEMA_TESTS

    filepath = SafePath.new('xml_files').join('COSD_9-0_Example.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD')
    end
  end

  test 'COSD v3-1 pathology sample XML files are valid' do
    return unless RUN_SCHEMA_TESTS

    source_folder = SafePath.new('xml_files').join('v3-1_dry_cosd_pathology')
    assert_nothing_raised do
      Dir.entries(source_folder).map do |xml_file|
        fname = source_folder.join(File.basename(xml_file))
        next unless SafeFile.extname(fname).delete('.').downcase == 'xml'
        puts "TESTING file => #{fname}" if print_output
        validate_cosd_schema(fname, 'COSD_Pathology')
      end
    end
  end

  test 'Generated COSD v9-0 sample file is passes schema' do
    return unless RUN_SCHEMA_TESTS

    filepath = tmp_safepath.join('sample_xml/COSD-v9-0_sample_items.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD')
    end

    filepath = tmp_safepath.join('sample_xml/COSD-v9-0_sample_choices.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD')
    end
  end

  test 'Generated COSD Pathology 4-1 sample file is passes schema' do
    return unless RUN_SCHEMA_TESTS

    filepath = tmp_safepath.join('sample_xml/COSD_Pathology-v4-1_sample_items.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD_Pathology')
    end

    filepath = tmp_safepath.join('sample_xml/COSD_Pathology-v4-1_sample_choices.xml')
    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD_Pathology')
    end
  end

  test 'Generated COSD Pathology 3-1 sample file is passes schema' do
    return unless RUN_SCHEMA_TESTS

    filepath = tmp_safepath.join('sample_xml/COSD_Pathology-v3-1_sample_items.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'COSD_Pathology')
    end
  end

  test 'Generated SACT sample file is passes schema' do
    return unless RUN_SCHEMA_TESTS

    filepath = tmp_safepath.join('sample_xml/SACT-v2-0_sample_items.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'SACT')
    end
  end

  test 'Generated MultipleRecordTypeDataset sample file is passes schema' do
    return unless RUN_SCHEMA_TESTS

    filepath = tmp_safepath.join('sample_xml/MultipleRecordTypeDataset-v1-0_sample_items.xml')

    puts "TESTING filepath => #{filepath}" if print_output
    assert_nothing_raised do
      validate_cosd_schema(filepath, 'MultipleRecordTypeDataset')
    end
  end

  KNOWN_SCHEMAS = {
    'COSD' => { '8-2' => ['COSD-v8-2', 'schema/COSD-v8-2.xsd'],
                '8-3' => ['COSD-v8-3', 'schema/COSD-v8-3.xsd'],
                '9-0' => ['COSD-v9-0', 'schema/COSD-v9-0.xsd'] },
    'SACT' => { '2-0' => ['SACT-v2-0', 'schema/SACT-v2-0.xsd'] },
    'COSD_Pathology' => { '3-1' => ['COSD_Pathology-v3-1', 'schema/COSD_Pathology-v3-1.xsd'],
                          '4-1' => ['COSD_Pathology-v4-1', 'schema/COSD_Pathology-v4-1.xsd'] },
    'MultipleRecordTypeDataset' =>
      { '1-0' => ['MultipleRecordTypeDataset-v1-0', 'schema/MultipleRecordTypeDataset-v1-0.xsd'] }
  }.freeze

  def validate_cosd_schema(filepath, dataset)
    document = read_xml_file(filepath)

    # Look for all COSD matching namespace definitions.
    # The implementation of this could probably be improved
    schema_versions = document.root.namespace_definitions.map do |definition|
      match = definition.href.match(/#{dataset}-v(.*)$/)
      match ? match[1] : nil
    end.compact
    if schema_versions.size != 1
      # No single schema identified
      root = document.root.dup
      root.children = ''
      raise "No schema version found (#{root})"
    end

    @schema_version = schema_versions.first

    schema = KNOWN_SCHEMAS[dataset][@schema_version]
    raise "Cannot validate #{dataset}-v#{@schema_version}" unless schema

    # schema_file = SafePath.new('tmp', schema.last)
    schema_file = tmp_safepath.join(schema.last)
    schema_exists = SafeFile.exists?(schema_file)
    raise SecurityError, 'Permissions denied. Cannot access the schema.' unless schema_exists

    schema = Nokogiri::XML::Schema(File.open(schema_file.to_s))

    messages = []
    errors = schema.validate(document)
    # Delete errors based on relaxation of rules
    structural_errors = remove_non_structural_schema_errors_from(errors)

    structural_errors.each do |error|
      message = "Line #{error.line}: #{error.message}"
      Rails.logger.debug(message)
      messages << message
    end
    return if messages.empty?

    full_message = messages.join("\n")
    full_message = "Truncated error log:\n#{full_message[0, 2000]}..." if full_message.length > 2000
    raise "Failed schema validation.\n#{full_message}"
  end

  def remove_non_structural_schema_errors_from(errors)
    reasons = [
      # Allow blank values:
      /The value ('' )?has a length of '0'/,
      /'' is not a valid value of the (local )?atomic type/,
      /The value '' is not an element/,
      /The value '' is not accepted by the pattern/,
      /Missing child element\(s\)/,
      # Delete all non-structural errors
      /not a valid value of the (local )?(atomic|union) type/,
      /\[facet '(enumeration|length|maxLength|minLength|pattern)'\]/,
      # An invidual file can be empty:
      /Element\s'RecordCount',\sattribute\s'value':\s\[facet\s'minInclusive'\]\s
      The\svalue\s'0'\sis\sless\sthan\sthe\sminimum\svalue\sallowed/x
    ]
    puts '=======' if print_output
    puts errors if print_output
    errors.delete_if do |error|
      reasons.any? { |resason| error.message =~ resason }
    end
  end

  def print_output
    @print_output ||= PRINT_TEST_OUTPUT
  end

  private

  def build_schema_files
    ensure_file_paths_exist("#{self.class.tmp_subdir}/schema")
    ensure_file_paths_exist("#{self.class.tmp_subdir}/sample_xml")
    datasets.each do |dataset|
      dataset.dataset_versions.each do |v|
        # Only building dataset versions to build change log
        next if legacy_schema?(dataset, v)

        # print "Building Dataset: #{v.name} Version: #{v.semver_version}\n"
        files = Xsd::SchemaFiles.new(v)
        files.components.each(&:save_file)
      end
    end
  end

  def legacy_schema?(dataset, version)
    return true if dataset.name == 'COSD' && version.semver_version == '8.1'
    return true if dataset.name == 'COSD' && version.semver_version == '8.2'
    return true if dataset.name == 'COSD' && version.semver_version == '8.3'
    return true if dataset.name == 'COSD_Pathology' && version.semver_version == '3.0'
  end

  def ensure_file_paths_exist(folder)
    return if File.exist? Rails.root.join('tmp', folder)

    FileUtils.mkdir_p(Rails.root.join('tmp', folder))
  end

  def datasets
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset])
  end

  def tmp_location
    @tmp_location ||= Rails.root.join('tmp').join(self.class.tmp_subdir)
  end

  def tmp_safepath
    @tmp_safepath ||= SafePath.new('tmp').join(self.class.tmp_subdir)
  end
end
