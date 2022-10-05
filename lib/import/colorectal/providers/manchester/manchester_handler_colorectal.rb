module Import
  module Colorectal
    module Providers
      module Manchester
        # Manchester R0A importer
        class ManchesterHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::R0a::R0aConstants
          include Import::Helpers::Colorectal::Providers::R0a::R0aHelper
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
            non_dosage_genotype_col    = []
            non_dosage_genotype2_col   = []
            non_dosage_genus_col       = []
            non_dosage_moltesttype_col = []
            non_dosage_exon_col        = []

            dosage_genotype_col    = []
            dosage_genotype2_col   = []
            dosage_genus_col       = []
            dosage_moltesttype_col = []
            dosage_exon_col        = []

            record.raw_fields.each do |raw_record|
              # if mlpa?(raw_record['exon']) && !control_sample?(raw_record) &&
              #    relevant_consultant?(raw_record)
              if raw_record['moleculartestingtype'].scan(/dosage/i).size.positive? &&
                 !control_sample?(raw_record) && relevant_consultant?(raw_record)
                dosage_genus_col.append(raw_record['genus'])
                dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
                dosage_exon_col.append(raw_record['exon'])
                dosage_genotype_col.append(raw_record['genotype'])
                dosage_genotype2_col.append(raw_record['genotype2'])
              end
              next unless !control_sample?(raw_record) && relevant_consultant?(raw_record)

              non_dosage_genus_col.append(raw_record['genus'])
              non_dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
              non_dosage_exon_col.append(raw_record['exon'])
              non_dosage_genotype_col.append(raw_record['genotype'])
              non_dosage_genotype2_col.append(raw_record['genotype2'])
            end
            @non_dosage_record_map = { genus: non_dosage_genus_col,
                                       moleculartestingtype: non_dosage_moltesttype_col,
                                       exon: non_dosage_exon_col,
                                       genotype: non_dosage_genotype_col,
                                       genotype2: non_dosage_genotype2_col }

            split_multiplegenes_nondosage_map(@non_dosage_record_map)

            @dosage_record_map = { genus: dosage_genus_col,
                                   moleculartestingtype: dosage_moltesttype_col,
                                   exon: dosage_exon_col,
                                   genotype: dosage_genotype_col,
                                   genotype2: dosage_genotype2_col }
            split_multiplegenes_dosage_map(@dosage_map)

            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            assign_and_populate_results_for(record)
            @logger.debug('DONE TEST')
          end
        end
      end
    end
  end
end
