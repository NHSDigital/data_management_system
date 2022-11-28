module Import
  module Colorectal
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
        class VariantProcessor
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants
          include Import::Helpers::Colorectal::Providers::Rq3::Rq3Helper

          def initialize(genocolorectal, record, logger)
            @genocolorectal = genocolorectal
            @record         = record
            @logger         = logger
            @genotypes      = []
            @posnegtest     = @record.raw_fields['overall2']
            @testresult     = @record.raw_fields['teststatus']
            @testreport     = @record.raw_fields['report']
            @genelist       = COLORECTAL_GENES_MAP[@record.raw_fields['indication']]
          end

          def process_variants_from_report
            return @genotypes unless @genelist

            case @posnegtest.upcase
            when 'P', '?', 'UV', 'PATHOGENIC'
              process_positive_records
            when 'N', 'NORMAL'
              process_negative_records
            else
              @logger.debug "UNRECOGNISED TAG FOR #{@record.raw_fields['indication']}"
            end

            @genotypes
          end

          private

          def process_result_without_colorectal_genes
            if @testreport.scan(CDNA_REGEX).size.positive?
              process_testreport_cdna_variants
            elsif @testreport.scan(CHR_VARIANTS_REGEX).size.positive?
              process_chromosomal_variant(@testreport)
            else
              process_malformed_variants
            end
          end

          def process_remainder
            process_full_screen if full_screen?(@record)
            @genocolorectal.add_gene_colorectal(colorectal_genes_from_test_result.join)
            @genocolorectal.add_gene_location('')
            @genocolorectal.add_status(2)
            @genotypes.append(@genocolorectal)
          end

          def colorectal_genes_from_test_result
            @testresult.scan(COLORECTAL_GENES_REGEX)
          end
        end
      end
    end
  end
end
