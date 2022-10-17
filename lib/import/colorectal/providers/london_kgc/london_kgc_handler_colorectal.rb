require 'possibly'

module Import
  module Colorectal
    module Providers
      module LondonKgc
        # London KGC importer
        class LondonKgcHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Kgc::KgcConstants
          include Import::Helpers::Colorectal::Providers::Kgc::KgcLynchHelper
          include Import::Helpers::Colorectal::Providers::Kgc::KgcLynchSpecificHelper
          include Import::Helpers::Colorectal::Providers::Kgc::KgcMsh26SpecificHelper
          include Import::Helpers::Colorectal::Providers::Kgc::KgcNonLynchGeneHelper
          include Import::Helpers::Colorectal::Providers::Kgc::KgcUnionLynchGeneHelper

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0

            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            genocolorectal.add_test_scope(:full_screen)
            add_organisationcode_testresult(genocolorectal)
            res = extract_lynch_from_record(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '697Q0'
          end

          def extract_lynch_from_record(genocolorectal, record)
            clinicomm = record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
            raw_genotype = record.raw_fields['genotype']
            genotypes = []
            # This block is to see if there are BROAD MLH1, MSH2, MSH6, EPCAM records
            if clinicomm.scan(LYNCH).count.positive? && clinicomm !~ LYNCH_SPECIFIC &&
               clinicomm !~ NON_LYNCH_REGEX && clinicomm !~ MSH2_6
              process_lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            # This block is to see if there are SPECIFIC MLH1, MSH2, MSH6, EPCAM records
            elsif clinicomm.scan(LYNCH_SPECIFIC).count.positive? &&
                  clinicomm !~ NON_LYNCH_REGEX && clinicomm !~ MSH2_6
              lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
              @logger.debug "FOUND LYNCH SPECIFIC genes #{lynchgenes_spec}"
              process_specific_lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            # This block is to see if there are SPECIFIC MSH2 and MSH6 records
            elsif clinicomm.scan(MSH2_6).count.positive? && clinicomm !~ NON_LYNCH_REGEX
              process_msh2_6_specific_genes(raw_genotype, clinicomm, genocolorectal, genotypes)
            # This block is to see if there are NON LYNCH records
            elsif clinicomm.scan(NON_LYNCH_REGEX).count.positive? && clinicomm !~ LYNCH_SPECIFIC &&
                  clinicomm !~ LYNCH && clinicomm !~ MSH2_6
              process_non_lynch_genes(raw_genotype, clinicomm, genocolorectal, genotypes)
            # This block is to see if there are NON LYNCH and BROAD LYNCH records
            elsif clinicomm.scan(NON_LYNCH_REGEX).count.positive? &&
                  clinicomm.scan(LYNCH).count.positive? && clinicomm !~ LYNCH_SPECIFIC &&
                  clinicomm !~ MSH2_6
              process_union_lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            elsif
              @logger.debug "NOTHING TO DO FOR #{clinicomm}"
            end
            genotypes
          end
        end
      end
    end
  end
end
