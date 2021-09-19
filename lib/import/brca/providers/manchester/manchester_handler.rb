module Import
  module Brca
    module Providers
      module Manchester
        # Manchester R0A importer
        class ManchesterHandler < Import::Brca::Core::ProviderHandler
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

            record.raw_fields.each { |raw_record| process_raw_record(raw_record) }

            @non_dosage_record_map = build_non_dosage_record_hash
            restructure_oddlynamed_nondosage_exons(@non_dosage_record_map)
            split_multiplegenes_nondosage_map

            @dosage_record_map = build_dosage_record_hash
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
            dosage_genus_col.append(raw_record['genus'])
            dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
            dosage_exon_col.append(raw_record['exon'])
            dosage_genotype_col.append(raw_record['genotype'])
            dosage_genotype2_col.append(raw_record['genotype2'])
          end

          def populate_non_dosage_data_from(raw_record)
            non_dosage_genus_col.append(raw_record['genus'])
            non_dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
            non_dosage_exon_col.append(raw_record['exon'])
            non_dosage_genotype_col.append(raw_record['genotype'])
            non_dosage_genotype2_col.append(raw_record['genotype2'])
          end

          def build_dosage_record_hash
            { genus: dosage_genus_col,
              moleculartestingtype: dosage_moltesttype_col,
              exon: dosage_exon_col,
              genotype: dosage_genotype_col,
              genotype2: dosage_genotype2_col }
          end

          def build_non_dosage_record_hash
            { genus: non_dosage_genus_col,
              moleculartestingtype: non_dosage_moltesttype_col,
              exon: non_dosage_exon_col,
              genotype: non_dosage_genotype_col,
              genotype2: non_dosage_genotype2_col }
          end

          def non_dosage_genotype_col
            @non_dosage_genotype_col ||= []
          end

          def non_dosage_genotype2_col
            @non_dosage_genotype2_col ||= []
          end

          def non_dosage_genus_col
            @non_dosage_genus_col ||= []
          end

          def non_dosage_moltesttype_col
            @non_dosage_moltesttype_col ||= []
          end

          def non_dosage_exon_col
            @non_dosage_exon_col ||= []
          end

          def dosage_genotype_col
            @dosage_genotype_col ||= []
          end

          def dosage_genotype2_col
            @dosage_genotype2_col ||= []
          end

          def dosage_genus_col
            @dosage_genus_col ||= []
          end

          def dosage_moltesttype_col
            @dosage_moltesttype_col ||= []
          end

          def dosage_exon_col
            @dosage_exon_col ||= []
          end
        end
      end
    end
  end
end
