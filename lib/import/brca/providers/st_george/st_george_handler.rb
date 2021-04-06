require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module StGeorge
        # Process St George-specific record details into generalized internal genotype format
        class StGeorgeHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age sex consultantcode collecteddate
                                   receiveddate authoriseddate servicereportidentifier
                                   providercode receiveddate sampletype] .freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s]+)|c\.\[(?<cdna>(.*?))\]/i.freeze
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
            add_organisationcode_testresult(genotype)
            process_cdna_change(genotype, record)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697N0'
          end

          def process_cdna_change(genotype, record)
            case record.raw_fields['genotype']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug "FAILED cdna change parse for: #{record.raw_fields['genotype']}"
            end
          end
        end
      end

      # NOTE: may need to integrate information from referral organisation and ref hospital number,
      # as well as possibly organisation code
      # What is a g number? (not genomic change)
      # ******************* Assign mutation and gene  ************************
      # Maybe(genotype.raw_fields['genotype']).each do |geno|
      #         # TODO: assign gene here when possible! Though it isn't always...
      #         # TODO: Not sure this regex is necessary, given that we're also using the extactor?
      #         case geno
      #         when /^b(?:r?c?a?)(?<brca_num>1|2) (?<remainder>.+)/i
      #           genotype.add_gene($LAST_MATCH_INFO[:brca_num].to_i)
      #           $LAST_MATCH_INFO[:remainder]
      #         end
      #     @failed_genotype_parse_counter += enotype.add_typed_location(@extractor.extract_type(geno))
      #       end
    end
  end
end
