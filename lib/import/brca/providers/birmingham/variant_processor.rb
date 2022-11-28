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
            if check_positive_record?
              process_positive_records
            elsif check_negative_record?
              process_negative_records
            end

            @genotypes
          end
        end
      end
    end
  end
end
