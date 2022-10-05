require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module Liverpool
        # Process Liverpool-specific record details into generalized internal genotype format
        class LiverpoolHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rep::Constants

          def process_fields(record)
            # return for colorectal cases
            return if record.raw_fields['investigation'].match(/HNPCC|Peutz-Jegher\sSyndrome/i)

            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            genotype.attribute_map['organisationcode_testresult'] = '69810'
            add_genetictestscope(genotype, record)
            add_test_status(genotype, record)
            result = process_variants_from_record(genotype, record)
            result.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_genetictestscope(genotype, record)
            testscope = record.raw_fields['testscope']&.downcase&.strip
            genotype.add_test_scope(TEST_SCOPE_MAP[testscope])
            return if genotype.attribute_map['genetictestscope'].present?

            genotype.add_test_scope(:no_genetictestscope)
          end

          def add_test_status(genotype, record)
            testresult = record.raw_fields['testresult']&.downcase&.strip
            teststatus = TEST_STATUS_MAP[testresult].presence || 4 # unknown
            genotype.add_status(teststatus)
            return unless 'heterozygous variant detected (mosaic)' == testresult

            genotype.add_geneticinheritance(:mosaic)
          end

          def process_variants_from_record(genotype, record)
            genotypes = []
            genotype.add_gene(record.raw_fields['gene'])
            if abnormal?(genotype)
              process_cdna_variant(genotype, record)
              process_protein_impact(genotype, record)
              process_exonic_variant(genotype, record)
            end
            genotypes.append(genotype)
            genotypes
          end

          def process_cdna_variant(genotype, record)
            variant = record.raw_fields['codingdnasequencechange']
            return unless variant.scan(CDNA_REGEX).size.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genotype, record)
            variant = record.raw_fields['proteinimpact']
            return unless variant.scan(PROTEIN_REGEX).size.positive?

            genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
          end

          def process_exonic_variant(genotype, record)
            variant = record.raw_fields['codingdnasequencechange']
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:variant])
            @logger.debug "SUCCESSFUL exon variant parse for: #{$LAST_MATCH_INFO[:exons]}"
          end

          def abnormal?(genotype)
            genotype.attribute_map['teststatus'] == 2
          end
        end
      end
    end
  end
end
