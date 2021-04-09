require 'ndr_import/table'
require 'ndr_import/file/registry'
require 'json'
require 'pry'
require 'csv'

# folder = File.expand_path('../', __dir__)
# $LOAD_PATH.unshift(folder) unless $LOAD_PATH.include?(folder)


module Import
  module Colorectal
    module Core
      # Reads in pseudonymised BRCA data, then invokes processing method on each
      # record. This base can be extended so that processing is the full importer,
      # or only the corrections preprocessor and a csv writer
      class ColorectalBase
        def initialize(filename, batch)
          @filename = filename
          @batch = batch
          @logger = Log.get_logger(batch.original_filename, batch.provider)
          @logger.info "Initialized import for #{@filename}" unless Rails.env.test?
          @logger.debug 'Available fields are: ' unless Rails.env.test?
          fw = Import::Utility::PseudonymisedFileWrapper.new(@filename)
          fw.process
          return if Rails.env.test?

          fw.available_fields.each { |field| @logger.debug "\t#{field}" }
        end

        def load
          # ensure_file_not_already_loaded # TODO: PUT THIS BACK, TESTING ONLY
          tables = NdrImport::File::Registry.tables(@filename, table_mapping.try(:format), {})

          return load_manchester(tables) if 'R0A' == @batch.provider

          # Enumerate over the tables
          # Under normal circustances, there will only be one table
          tables.each do |_tablename, table_content|
            table_mapping.transform(table_content).each do |klass, fields, _index|
              build_and_process_records(klass, fields)
            end
          end
        end

        def load_manchester(tables)
          tables.each do |_tablename, table_content|
            mapped_table = table_mapping.transform(table_content)
            # Ignore the first row, it doesn't contain data
            grouped_records_by_linkage = mapped_table.to_a[1..-1].group_by do |_klass, fields, _i|
              grouping = fields.values_at('pseudo_id1', 'pseudo_id2')
              rawtext = JSON.parse(fields['rawtext_clinical.to_json'])
              grouping << rawtext['servicereportidentifier']
              grouping << rawtext['authoriseddate']
              grouping
            end
            cleaned_records = []
            # From each set of grouped records, build a normalised record
            grouped_records_by_linkage.each do |_linkage, records|
              cleaned_records << [records.first.first, grouped_rawtext_record_from(records)]
            end
            cleaned_records.each { |klass, fields| build_and_process_records(klass, fields) }
          end
        end

        private

        # `records` is an array of many [klass, fields, index]
        def grouped_rawtext_record_from(records)
          # Use the first record's `fields` as a starting point
          fields                 = records.first[1].dup
          raw_records_array      = records.map { |record| record[1] }
          rawtext_clinical_array = raw_records_array.map do |raw_record|
            JSON.parse(raw_record['rawtext_clinical.to_json'])
          end
          fields['rawtext_clinical.to_json'] = rawtext_clinical_array.to_json

          fields
        end

        def build_and_process_records(klass, fields)
          Pseudo::Ppatient.transaction { process_records(klass, fields) }
        end

        def file
          @file ||= SafeFile.exist?(@filename) ? SafeFile.new(@filename, 'r') : nil
        end

        # Load the required mapping file based on @batch.e_type
        def table_mapping
          # TODO: Decide on e_type names
          mapping_file = case @batch.e_type
                         when 'PSMOLE'
                           'brca_mapping.yml'
                         else
                           raise "No mapping found for #{@batch.e_type}"
                         end
          YAML.load_file(SafePath.new('mappings_config').join(mapping_file))
        end
      end
    end
  end
end
