require 'possibly'
require 'import/storage_manager/persister'
require 'pry'
require 'import/brca/core/provider_handler'
require 'import/helpers/colorectal/providers/rq3/rq3_constants'

module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Cambridge-specific record details into generalized internal genotype format
        class BirminghamHandlerColorectal < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            process_genetictestscope(genocolorectal, record)
            teststatus_report_inconsistency(genocolorectal, record)
            @persister.integrate_and_store(genocolorectal)
          end

          def process_genetictestscope(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |tscope|
              if TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]
                genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip])
                @logger.debug 'Processed genetictestscope '\
                              "#{TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]} for #{tscope}"
              else @logger.debug 'UNABLE to process genetictestscope'
              end
            end
          end

          def teststatus_report_inconsistency(genocolorectal, record)
            if COLORECTAL_GENES_MAP[record.raw_fields['indication']] &&
              record.raw_fields['teststatus'].scan(COLORECTAL_GENES_REGEX).size > 0 && 
              record.raw_fields['report'].scan(COLORECTAL_GENES_REGEX).size > 0 &&
               record.raw_fields['teststatus'].scan(COLORECTAL_GENES_REGEX).uniq.size != record.raw_fields['report'].scan(COLORECTAL_GENES_REGEX).uniq.size
              binding.pry
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
