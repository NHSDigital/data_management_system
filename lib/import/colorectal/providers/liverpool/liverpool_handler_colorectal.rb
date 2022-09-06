require 'pry'
require 'possibly'

module Import
  module Colorectal
    module Providers
      module Liverpool
        # Process Liverpool-specific record details into generalized internal genocolorectal format
        class LiverpoolHandlerColorectal < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rep::Constants

          def process_fields(record)
            # return for brca cases
            return if record.raw_fields['investigation'].match(/BRCA/i)

            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS)
            genocolorectal.attribute_map['organisationcode_testresult'] = '69810'
            add_genetictestscope(genocolorectal, record)
            add_test_status(genocolorectal, record)
            result = process_variants_from_record(genocolorectal, record)
            result.each { |cur_genocolorectal| @persister.integrate_and_store(cur_genocolorectal) }
          end

          def add_genetictestscope(genocolorectal, record)
            testscope = record.raw_fields['testscope']&.downcase&.strip
            genocolorectal.add_test_scope(TEST_SCOPE_MAP[testscope])
            return if genocolorectal.attribute_map['genetictestscope'].present?

            genocolorectal.add_test_scope(:no_genetictestscope)
          end

          def add_test_status(genocolorectal, record)
            testresult = record.raw_fields['testresult']&.downcase&.strip
            teststatus = TEST_STATUS_MAP[testresult].presence || 4 # unknown
            genocolorectal.add_status(teststatus)
            return unless 'heterozygous variant detected (mosaic)' == testresult

            genocolorectal.add_geneticinheritance(:mosaic)
          end

          def process_variants_from_record(genocolorectal, record)
            genocolorectals = []
            genocolorectal.add_gene_colorectal(record.raw_fields['gene'])
            if abnormal?(genocolorectal)
              process_cdna_variant(genocolorectal, record)
              process_protein_impact(genocolorectal, record)
              process_exonic_variant(genocolorectal, record)
            end
            genocolorectals.append(genocolorectal)
            genocolorectals
          end

          def process_cdna_variant(genocolorectal, record)
            variant = record.raw_fields['codingdnasequencechange']
            return unless variant.scan(CDNA_REGEX).size.positive?

            genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genocolorectal, record)
            variant = record.raw_fields['proteinimpact']
            return unless variant.scan(PROTEIN_REGEX).size.positive?

            genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
            @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
          end

          def process_exonic_variant(genocolorectal, record)
            variant = record.raw_fields['codingdnasequencechange']
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genocolorectal.add_exon_location($LAST_MATCH_INFO[:exons])
            genocolorectal.add_variant_type($LAST_MATCH_INFO[:variant]&.downcase)
            @logger.debug "SUCCESSFUL exon variant parse for: #{$LAST_MATCH_INFO[:exons]}"
          end

          def abnormal?(genocolorectal)
            genocolorectal.attribute_map['teststatus'] == 2
          end
        end
      end
    end
  end
end
