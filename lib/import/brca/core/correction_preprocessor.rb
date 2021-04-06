require 'csv'
require 'pry'
module Import
  module Brca
    module Core
      # Sometimes labs just write the wrong thing in a field, this class allows us
      # patch such errors before they reach the main extraction framework
      class CorrectionPreprocessor
        def self.from_batch(batch)
          @logger = Import::Log.get_auxiliary_logger
          provider = batch.provider
          corrections_file =
            case batch.original_filename
            when %r{(?<root_path>.+/#{provider}/).*}i
              $LAST_MATCH_INFO[:root_path]
            else
              @logger.error "Could not extract path to corrections file for #{provider}; "\
              'preprocessing disabled'
              return nil
            end
          file_name = SafePath.new('pseudonymised_data').join(corrections_file).
                      join('corrections.csv').
                      to_s
          unless File.exist?(file_name)
            @logger.warn "No extant corrections file for #{provider}; disabling preprocessor"
            return nil
          end

          @preprocessor = Import::Brca::Core::CorrectionPreprocessor.new(file_name, batch)
          @preprocessor.load_overrides
          @preprocessor
        end

        def initialize(override_file, batch)
          @override_file = override_file
          @logger = Log.get_auxiliary_logger
          @corrections_list = []
          @failed_correction_counter = 0
          @attempted_correction_counter = 0
          @batch = batch
          @logger.info 'Loaded corrections preprocessor'
        end

        def load_overrides
          line_counter = 0
          CSV.foreach(@override_file) do |row|
            if row.size == 1
              # Header; do nothing
            elsif row.size == 8
              @corrections_list.push(Correction.new(*(0..7).map { |x| row[x] }))
            else
              @logger.debug "Line #{line_counter} contained unexpected" \
                            " number of fields: #{row.size}"
            end
            line_counter += 1
          end
          @total_lines = line_counter
        end

        def apply_correction(record)
          relevant_corrections = find_corrections(record)
          return if relevant_corrections.empty?

          @attempted_correction_counter += relevant_corrections.size
          mapped_corrections, raw_corrections = relevant_corrections.partition(&:mapped)
          mapped_corrections.each do |correction|
            @failed_correction_counter += 1 unless correction.apply(record.mapped_fields)
          end
          raw_corrections.each do |correction|
            @failed_correction_counter += 1 unless correction.apply(record.raw_fields)
          end
        end

        def find_corrections(_record)
          # TODO: actually implement this
          []
        end

        def summarize
          @logger.info ' ******************** Corrections Report ********************* '
          @logger.info "CorrectionPreprocessor has loaded #{@total_lines} corrections"
          @logger.info "Failed to apply #{@failed_correction_counter} corrections of "\
          "#{@attempted_correction_counter} attempted"
        end
      end

      # Wrapper object for storing correction information
    end
  end
end

# Format:
# file_name | line_num | id1 | id2 | field_name | old_value | new_value

if __FILE__ == $PROGRAM_NAME
  cor = Utility::CorrectionPreprocessor.new('utility/corrections_test.csv')
  cor.load_overrides
end
