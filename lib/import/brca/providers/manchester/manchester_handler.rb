module Import
  module Brca
    module Providers
      module Manchester
        # Manchester R0A importer
        class ManchesterHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::R0a::R0aConstants
          include Import::Helpers::Brca::Providers::R0a::R0aHelper
          include Import::Helpers::Brca::Providers::R0a::R0aNondosageHelper
          include Import::Helpers::Brca::Providers::R0a::R0aDosageHelper

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          # TODO: Further boyscouting
          def process_fields(record)
            @logger.debug('STARTING PARSING')
            # Assigns a new array for each missing key in the Hash
            # to ensure a new object is created each time
            @dosage_record_map     = Hash.new { |hash, key| hash[key] = [] }
            @non_dosage_record_map = Hash.new { |hash, key| hash[key] = [] }

            # For clarity, `raw_fields` contains multiple raw records, unlike other providers
            record.raw_fields.each { |raw_record| process_raw_record(raw_record) }

            restructure_oddlynamed_nondosage_exons(@non_dosage_record_map)
            split_multiplegenes_nondosage_map

            restructure_oddlynamed_nondosage_exons(@dosage_record_map)
            split_multiplegenes_dosage_map
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            assign_and_populate_results_for(record)
            @logger.debug('DONE TEST')
          end

          def process_raw_record(raw_record)
            populate_dosage_data_from(raw_record) if dosage_record?(raw_record)
            return unless relevant_consultant?(raw_record)

            populate_non_dosage_data_from(raw_record)
          end

          def dosage_record?(raw_record)
            !raw_record.nil? && !raw_record['moleculartestingtype'].nil? &&
              raw_record['moleculartestingtype'].scan(/dosage/i).size.positive? &&
              !control_sample?(raw_record) && relevant_consultant?(raw_record)
          end

          def populate_dosage_data_from(raw_record)
            @dosage_record_map[:genus].append(raw_record['genus'])
            @dosage_record_map[:moleculartestingtype].append(raw_record['moleculartestingtype'])
            @dosage_record_map[:exon].append(raw_record['exon'])
            @dosage_record_map[:genotype].append(raw_record['genotype'])
            @dosage_record_map[:genotype2].append(raw_record['genotype2'])
          end

          def populate_non_dosage_data_from(raw_record)
            @non_dosage_record_map[:genus].append(raw_record['genus'])
            @non_dosage_record_map[:moleculartestingtype].append(raw_record['moleculartestingtype'])
            @non_dosage_record_map[:exon].append(raw_record['exon'])
            @non_dosage_record_map[:genotype].append(raw_record['genotype'])
            @non_dosage_record_map[:genotype2].append(raw_record['genotype2'])
          end
        end
      end
    end
  end
end
