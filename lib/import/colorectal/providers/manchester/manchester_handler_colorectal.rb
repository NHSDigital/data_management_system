require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'

module Import
  module Colorectal
    module Providers
      module Manchester
        class ManchesterHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate practitionercode genomicchange
                                        specimentype].freeze

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
            @persister.integrate_and_store(genocolorectal)
          end

        end
      end
    end
  end
end