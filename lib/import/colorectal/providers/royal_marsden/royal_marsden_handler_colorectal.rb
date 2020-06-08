require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'

module Import
  module Colorectal
    module Providers
      module RoyalMarsden
        class RoyalMarsdenHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate practitionercode genomicchange
                                        specimentype].freeze
        
                                        COLORECTAL_GENES_REGEX = /(?<colorectal> EPCAM|MLH1|MSH2|
                                                                  MSH6|PMS2)/xi .freeze # Added by

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
            process_gene(genocolorectal, record)
            @persister.integrate_and_store(genocolorectal)
          end
          
          def process_gene(genocolorectal, record)
            genes=record.raw_fields['gene']
            if COLORECTAL_GENES_REGEX.match(genes)
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              @successful_gene_counter += 1
            end
          end

        end
      end
    end
  end
end