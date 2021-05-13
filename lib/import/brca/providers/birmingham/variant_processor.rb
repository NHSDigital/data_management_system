module Import
  module Brca
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
        class VariantProcessor
          include Import::Helpers::Brca::Providers::Rq3::Rq3Constants
          include Import::Helpers::Brca::Providers::Rq3::Rq3Helper

          def initialize(genotype, record, logger)
            @genotype = genotype
            @record         = record
            @logger         = logger
            @genotypes      = []
            @posnegtest     = @record.raw_fields['overall2']
            @testresult     = @record.raw_fields['teststatus']
            @testreport     = @record.raw_fields['report']
            @genelist       = BRCA_GENES_MAP[@record.raw_fields['indication']]
            @testprocessor = TestresultProcessor.new(@genotype,@record,@testresult)
          end

          def process_variants_from_report
            if @posnegtest.upcase == 'P'
              @logger.debug 'ABNORMAL TEST'
              if brca_genes_from_test_result.empty?
                process_result_without_brca_genes
              elsif @testresult.scan(CDNA_REGEX).size.positive?
                process_testresult_cdna_variants(@testresult, @testreport, @genelist,
                                                 @genotypes, @record, @genotype)
              elsif @testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants(@record, @testresult, @testreport, @genotypes, @genotype)
              elsif @testresult.scan(CDNA_REGEX).blank? &&
                    @testresult.scan(BRCA_REGEX).size.positive? &&
                    @testreport.scan(BRCA_REGEX).size.positive?
                process_positive_malformed_variants(@genelist, @genotypes, @testresult,
                                                    @testreport, @record, @genotype)
              elsif @testreport.scan(BRCA_REGEX).blank? &&
                    @testresult.scan(BRCA_REGEX).size.positive?
                @logger.debug 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHH'
                process_empty_testreport_results(@testresult, @genelist, @genotypes, @record,
                                                 @genotype)
                # elsif @testresult.match(/No known pathogenic/i)
                #   process_negative_genes(@genelist, @genotypes, @genocolorectal)
                # else
                #   process_remainder
              end
            elsif @posnegtest.upcase == 'N' &&
                  @testresult.scan(/INTERNAL REPORT/i).size.zero? &&
                  !@testreport.nil?
              process_negative_records(@genelist, @genotypes, @testresult,
                                       @testreport, @record, @genotype)
              # else
              #   @logger.debug "UNRECOGNISED TAG FOR #{@record.raw_fields[indication]}"
            end

            @genotypes
          end

          private

          def process_result_without_brca_genes
            if @testreport.scan(CDNA_REGEX).size.positive?
              process_testreport_cdna_variants(@testreport, @genotypes, @genotype)
            elsif @testreport.scan(CHR_VARIANTS_REGEX).size.positive?
              process_chromosomal_variant(@testreport, @genelist, @genotypes,
                                          @record, @genotype)
              # else
              #   process_malformed_variants(@testresult, @testreport, @genelist, @genotypes,
              #                              @genotype, @record)
            end
          end

          def process_remainder
            if full_screen?(@record)
              process_full_screen(@record, @testresult, @testreport, @genotypes, @genotype)
            end
            @genotype.add_gene_colorectal(colorectal_genes_from_test_result.join)
            @genotype.add_gene_location('')
            @genotype.add_status(2)
            @genotypes.append(@genotype)
          end

          def brca_genes_from_test_result
            @testresult.scan(BRCA_REGEX)
          end
        end
      end
    end
  end
end
