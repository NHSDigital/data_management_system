require 'possibly'

module Import
  module Brca
    module Providers
      module LondonKgc
        # London KGC importer
        class LondonKgcHandler < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Brca::Providers::Kgc::KgcConstants
          include Import::Helpers::Brca::Providers::Kgc::KgcBrcaHelper
          include Import::Helpers::Brca::Providers::Kgc::KgcTp53GenesHelper

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0

            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS_COLO)
            genotype.add_test_scope(:full_screen)
            add_organisationcode_testresult(genotype)
            res = extract_variants_from_record(genotype, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697Q0'
          end

          def extract_variants_from_record(genotype, record)
            clinicomm = record.raw_fields['all clinical comments (semi colon separated).'\
                                          'all clinical comment text']
            raw_genotype = record.raw_fields['genotype']
            genotypes = []
            if clinicomm.scan(BRCA_TP53).count.positive? && clinicomm =~ BRCA_TP53
              process_tp53_entries(raw_genotype, clinicomm, genotype, genotypes)
            elsif clinicomm.scan(BRCA).count.positive? && clinicomm =~ BRCA
              process_brcagenes(raw_genotype, clinicomm, genotype, genotypes)
            # This block is to see if there are NON LYNCH and BROAD LYNCH records
            else
              @logger.debug "NOTHING TO DO FOR #{clinicomm}"
            end
            genotypes
          end
        end
      end
    end
  end
end
