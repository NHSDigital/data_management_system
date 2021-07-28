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

          BRCA_GENES_REGEX = /(?<brca>BRCA1|
                                     BRCA2|
                                     ATM|
                                     CHEK2|
                                     PALB2|
                                     MLH1|
                                     MSH2|
                                     MSH6|
                                     MUTYH|
                                     SMAD4|
                                     NF1|
                                     NF2|
                                     SMARCB1|
                                     LZTR1)/xi.freeze
          EXON_VARIANT_REGEX = /exon\s(?<exons>[0-9]+(-[0-9]+)?)\s(?<variant>del|dup|ins)/i.freeze

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
            process_genetictestcope(genotype, record)
            process_gene(genotype, record)
            process_cdna_change(genotype, record)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '697N0'
          end

          def process_genetictestcope(genotype, record)
            moltesttype = record.raw_fields['moleculartestingtype']
            if moltesttype.scan(/pred|conf|targeted/i).size.positive? ||
              moltesttype.scan(/BRCA(1|2) exon deletion\/duplication/i).size.positive?
              genotype.add_test_scope(:targeted_mutation)
            elsif moltesttype.scan(/screen/i).size.positive?
              genotype.add_test_scope(:full_screen)
            elsif moltesttype.empty?
              @logger.debug "Empty moleculartestingtype"
            elsif moltesttype == 'Store'
              @logger.debug "Unknown moleculartestingtype"
            elsif moltesttype == 'BRCA1 & 2 exon deletion & duplication analysis'
              genotype.add_test_scope(:full_screen)
            else binding.pry
            end
          end

          def process_cdna_change(genotype, record)
            if positive_cdna?(genotype, record)
              process_cdna_variant(genotype, record)
            elsif positive_exonvariant?(genotype, record)
              process_exonic_variant(genotype, record)
            elsif normal?(genotype, record)
              process_normal_record(genotype, record)
              @logger.debug "NORMAL record parse for: #{record.raw_fields['genotype']}"
            else
              @logger.debug "FAILED variant parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_gene(genotype, record)
            if record.raw_fields['genotype'].scan(BRCA_GENES_REGEX).size.positive?
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:brca]}"
            elsif deprecated_brca_genenames?(genotype, record)
              genename = record.raw_fields['genotype'].scan(/BR1|BR2/i).flatten.join
              genename = genename.gsub('BR1', 'BRCA1').gsub('BR2', 'BRCA2')
              genotype.add_gene_location(genename)
              @logger.debug "SUCCESSFUL gene parse for: #{genename}"
            else
              @logger.debug 'FAILED gene parse for: ' \
                            "#{record.raw_fields['genotype']}"
            end
          end

          def deprecated_brca_genenames?(genotype, record)
            genename = record.raw_fields['genotype'].scan(/BR1|BR2/i).flatten.join
            genename == 'BR1' || genename == 'BR2'
          end

          def process_exonic_variant(genotype, record)
            if record.raw_fields['genotype'].scan(EXON_VARIANT_REGEX).size.positive?
              genotype.add_exon_location($LAST_MATCH_INFO[:exons])
              genotype.add_variant_type($LAST_MATCH_INFO[:variant])
              genotype.add_status(2)
              @logger.debug "SUCCESSFUL cdna change parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_cdna_variant(genotype, record)
            if record.raw_fields['genotype'].scan(CDNA_REGEX).size.positive?
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype.add_status(2)
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            end
          end

          def process_normal_record(genotype, record)
              genotype.add_status(1)
              @logger.debug "SUCCESSFUL cdna change parse for: #{record.raw_fields['genotype']}"
          end

          def normal?(genotype, record)
            variant = record.raw_fields['genotype']
            variant.scan(/NO PATHOGENIC|Normal|N\/N|NOT DETECTED/i).size.positive?
          end

          def positive_cdna?(genotype, record)
            variant = record.raw_fields['genotype']
            variant.scan(CDNA_REGEX).size.positive?
          end

          def positive_exonvariant?(genotype, record)
            variant = record.raw_fields['genotype']
            variant.scan(EXON_VARIANT_REGEX).size.positive?
          end
        end
      end
    end
  end
end
