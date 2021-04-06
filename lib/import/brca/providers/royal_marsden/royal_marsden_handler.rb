require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module RoyalMarsden
        # BRCA importer for Royal Marsden Trust
        class RoyalMarsdenHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'full gene' => :full_screen,
                             'specific mutation' => :targeted_mutation } .freeze

          PASS_THROUGH_FIELDS = %w[age sex consultantcode collecteddate
                                   receiveddate authoriseddate servicereportidentifier
                                   providercode receiveddate sampletype] .freeze
          CDNA_REGEX = /c\.(?<cdna>.+);\s|c\.(?<cdna>.+)(?![p\.])$|c\.((?<cdna>.+))\_p\./i.freeze

          def initialize(batch)
            @extractor = Import::ExtractionUtilities::LocationExtractor.new
            @failed_genotype_parse_counter = 0
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            process_cdna_change(genotype, record)
            add_organisationcode_testresult(genotype)
            process_gene(genotype, record)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '696L0'
          end

          def process_cdna_change(genotype, record)
            case record.raw_fields['teststatus']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            end
          end

          def process_gene(genotype, record)
            gene = record.mapped_fields['gene'].to_i
            case gene
            when Integer then
              if (7..8).cover? gene
                genotype.add_gene(record.mapped_fields['gene'].to_i)
                @logger.debug 'SUCCESSFUL gene parse for:' \
                              "#{record.mapped_fields['gene'].to_i}"
              else
                @logger.debug 'FAILED gene parse for: ' \
                              "#{rrecord.mapped_fields['gene'].to_i}"
              end
            end
          end
        end
      end
    end
  end
end
