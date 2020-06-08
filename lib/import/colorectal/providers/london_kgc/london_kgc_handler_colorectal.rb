require 'possibly'
require 'import/storage_manager/persister'
require 'import/brca/core/provider_handler'
require 'pry'

module Import
  module Colorectal
    module Providers
      module LondonKgc
        class LondonKgcHandlerColorectal < Import::Brca::Core::ProviderHandler

  PASS_THROUGH_FIELDS_COLO = %w[age sex consultantcode collecteddate
                           receiveddate authoriseddate servicereportidentifier
                           providercode receiveddate ] .freeze

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
            res = extract_lynch_from_record(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end


          def extract_lynch_from_record(genocolorectal, record)
            clinicomm = record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
            genotypes = []
            if /Lynch Syndrome/i.match(clinicomm)
              genotypes.append(genocolorectal)
            end
            genotypes
          end

        end
      end
    end
  end
end
