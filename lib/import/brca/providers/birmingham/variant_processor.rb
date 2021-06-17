module Import
  module Brca
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
        class VariantProcessor
          include Import::Helpers::Brca::Providers::Rq3::Rq3Constants
          include Import::Helpers::Brca::Providers::Rq3::Rq3Helper

          def initialize(genotype, record, logger)
            @genotype   = genotype
            @record     = record
            @logger     = logger
            @genotypes  = []
            @posnegtest = @record.raw_fields['overall2']
            @testresult = @record.raw_fields['teststatus']
            @testreport = @record.raw_fields['report']
            @genelist   = BRCA_GENES_MAP[@record.raw_fields['indication']]
          end

          def process_variants_from_report
            if @posnegtest.upcase == 'P'
              @logger.debug 'ABNORMAL TEST'
              if brca_genes_from_test_result.empty?
                process_result_without_brca_genes
              elsif @testresult.scan(/no evidence(?!\.).+[^.]|no further(?!\.).+[^.]/i).join.size.positive?
                process_noevidence_records
              elsif @testresult.scan(CDNA_REGEX).size.positive?
                process_testresult_cdna_variants
              elsif @testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants
              elsif @testresult.scan(CDNA_REGEX).blank? &&
                    @testresult.scan(BRCA_REGEX).size.positive? &&
                    @testreport.scan(BRCA_REGEX).size.positive?
                process_positive_malformed_variants
              elsif @testreport.scan(BRCA_REGEX).blank? &&
                    @testresult.scan(BRCA_REGEX).size.positive?
                @logger.debug 'TESTREPORT EMPTY: EXTRACTING ONLY FROM TESTRESULTS'
                process_empty_testreport_results
              end
            elsif @posnegtest.upcase == 'N' &&
                  @testresult.scan(/INTERNAL REPORT/i).size.zero? &&
                  !@testreport.nil?
              process_negative_records
            end

            @genotypes
          end

          private

          def process_result_without_brca_genes
            if @testreport.scan(CDNA_REGEX).size.positive?
              process_testreport_cdna_variants
            elsif @testreport.scan(CHR_VARIANTS_REGEX).size.positive?
              process_chromosomal_variant(@testreport)
            end
          end

          def brca_genes_from_test_result
            @testresult.scan(BRCA_REGEX)
          end
        end
      end
    end
  end
end
