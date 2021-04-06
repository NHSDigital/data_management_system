
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

            if @posnegtest.upcase == 'P'
              @logger.debug 'ABNORMAL TEST'
              if @testresult.scan(/MYH/).size.positive?
                process_mutyh_specific_variants(@testresult, @genelist, @genotypes,
                                                @genocolorectal, @record)
              elsif colorectal_genes_from_test_result.empty?
                process_result_without_colorectal_genes
              elsif @testresult.scan(CDNA_REGEX).size.positive?
                process_testresult_cdna_variants(@testresult, @testreport, @genelist,
                                                 @genotypes, @record, @genocolorectal)
              elsif @testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants(@record, @testresult, @testreport, @genotypes, @genocolorectal)
              elsif @testresult.match(/No known pathogenic/i)
                process_negative_genes(@genelist, @genotypes, @genocolorectal)
              else
                process_remainder
              end
            elsif @posnegtest.upcase == 'N'
              process_negative_records(@genelist, @genotypes, @testresult,
                                       @testreport, @record, @genocolorectal)
            else
              @logger.debug "UNRECOGNISED TAG FOR #{@record.raw_fields[indication]}"
            end

            @genotypes
          end

          private

          def process_result_without_colorectal_genes
            if @testreport.scan(CDNA_REGEX).size.positive?
              process_testreport_cdna_variants(@testreport, @genotypes, @genocolorectal)
            elsif @testreport.scan(CHR_VARIANTS_REGEX).size.positive?
              process_chromosomal_variant(@testreport, @genelist, @genotypes,
                                          @record, @genocolorectal)
            else
              process_malformed_variants(@testresult, @testreport, @genelist, @genotypes,
                                         @genocolorectal, @record)
            end
          end

          def process_remainder
            if full_screen?(@record)
              process_full_screen(@record, @testresult, @testreport, @genotypes, @genocolorectal)
            end
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
