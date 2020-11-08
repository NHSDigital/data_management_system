require 'import/storage_manager/persister'
require 'import/brca/core/provider_handler'
require 'import/helpers/colorectal/providers/r0a/r0a_constants'
require 'import/helpers/colorectal/providers/r0a/r0a_helper'

module Import
  module Colorectal
    module Providers
      module Manchester
        # Manchester R0A importer
        class ManchesterHandlerColorectal < Import::Brca::Core::ProviderHandler
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

          def process_fields(record)
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
              if !control_sample?(raw_record) && relevant_consultant?(raw_record)
                non_dosage_genus_col.append(raw_record['genus'])
                non_dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
                non_dosage_exon_col.append(raw_record['exon'])
                non_dosage_genotype_col.append(raw_record['genotype'])
                non_dosage_genotype2_col.append(raw_record['genotype2'])
              elsif mlpa?(raw_record['exon']) && !control_sample?(raw_record) &&
                    relevant_consultant?(raw_record)
                dosage_genus_col.append(raw_record['genus'])
                dosage_moltesttype_col.append(raw_record['moleculartestingtype'])
                dosage_exon_col.append(raw_record['exon'])
                dosage_genotype_col.append(raw_record['genotype'])
                dosage_genotype2_col.append(raw_record['genotype2'])
              else
                break
              end
            end

            @non_dosage_record_map = { genus: non_dosage_genus_col,
                                       moleculartestingtype: non_dosage_moltesttype_col,
                                       exon: non_dosage_exon_col,
                                       genotype: non_dosage_genotype_col,
                                       genotype2: non_dosage_genotype2_col }

            @dosage_record_map = { genus: dosage_genus_col,
                                   moleculartestingtype: dosage_moltesttype_col,
                                   exon: dosage_exon_col,
                                   genotype: dosage_genotype_col,
                                   genotype2: dosage_genotype2_col }

            @stringed_moltesttype = @non_dosage_record_map[:moleculartestingtype].flatten.join(',')
            @stringed_exon = @non_dosage_record_map[:exon].flatten.join(',')

            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            assign_and_populate_results_for(record)
          end

          def testscope_from_rawfields(genocolorectal, record)
            moltesttypes = []
            genera       = []
            exons        = []
            record.raw_fields.map do |raw_record|
              moltesttypes.append(raw_record['moleculartestingtype'])
              genera.append(raw_record['genus'])
              exons.append(raw_record['exon'])
            end

            add_test_scope_to(genocolorectal, moltesttypes, genera, exons)
          end

          def assign_gene_mutation(genocolorectal, _record)
            genotypes = []
            genes = []
            if non_dosage_test?
              process_non_dosage_test_exons(genes)
              tests = tests_from_non_dosage_record(genes)
              grouped_tests = grouped_tests_from(tests)
              process_grouped_non_dosage_tests(grouped_tests, genocolorectal, genotypes)
            elsif dosage_test?
              process_dosage_test_exons(genes)
              tests = tests_from_dosage_record(genes)
              grouped_tests = grouped_tests_from(tests)
              process_grouped_dosage_tests(grouped_tests, genocolorectal, genotypes)
            end
            genotypes
          end
        end
      end
    end
  end
end
