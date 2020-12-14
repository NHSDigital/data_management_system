require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'

module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Cambridge-specific record details into generalized internal genotype format
        class BirminghamHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age sex consultantcode servicereportidentifier providercode
                                        authoriseddate receiveddate moleculartestingtype
                                        specimentype].freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          TEST_SCOPE_MAP_COLO_COLO = { '100kgp confirmation'  => :full_screen,
                                       'carrier testing'      => :targeted_mutation,
                                       'confirmation'         => :targeted_mutation,
                                       'diagnosis'            => :full_screen,
                                       'family studies'       => :targeted_mutation,
                                       'follow-up'            => :targeted_mutation,
                                       'indirect testing'     => :full_screen,
                                       'pold1/ pole analysis' => :full_screen,
                                       'prenatal diagnosis'   => :targeted_mutation,
                                       'presymptomatic'       => :targeted_mutation }.freeze
                                       
          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11|
                                                NTHL1)/xi . freeze # Added by Francesco

          CDNA_REGEX_COLO = /c\.(?<cdna>.*)/i.freeze
          PROTEIN_REGEX_COLO = /p.(?:\((?<impact>.*)\))/.freeze
          EXON_LOCATION_REGEX_COLO = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i.freeze

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            process_genetictestscope(genocolorectal, record)
            @persister.integrate_and_store(genocolorectal)
          end

          def process_genetictestscope(genocolorectal, record)
            if record.raw_fields['moleculartestingtype']
              tscope = record.raw_fields['moleculartestingtype']
              genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip])
              @logger.debug 'Processed genetictestscope'\
                            "#{TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]} for #{tscope}"
            else @logger.debug 'UNABLE to process genetictestscope'
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of "\
            "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of"\
            "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genocolorectals failed to parse: #{@failed_genocolorectal_counter}"\
            "of #{@lines_processed} attempted"
            @logger.info "Num positive tests: #{@positive_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num negative tests: #{@negative_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
          end
        end
      end
    end
  end
end
