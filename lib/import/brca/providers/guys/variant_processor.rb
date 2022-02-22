module Import
  module Brca
    module Providers
      module Guys
        # Process Leeds-specific record details
        class VariantProcessor

          attr_accessor :report_string
          attr_accessor :genotype_string
          attr_accessor :genetictestscope_field
          
          
          def initialize(genotype, record, logger)
            @genotype   = genotype
            @record     = record
            @logger     = logger
            @genotypes  = []
            @aj_report_date = record.raw_fields['ashkenazi assay report date']
            @aj_assay_result = record.raw_fields['ashkenazi assay result']
            @predictive_report_date = record.raw_fields['predictive report date']
            @brca1_mutation = record.raw_fields['brca1 mutation']
            @brca2_mutation = record.raw_fields['brca2 mutation']
          end

          # def add_molecular_testing_type
          #   return unless @record.raw_fields['moleculartestingtype'].present?
          #
          #   mtype = @record.raw_fields['moleculartestingtype']
          #   if TEST_TYPE_MAP[mtype.downcase.strip] == :diagnostic &&
          #     @genotype_string.scan(/unaffected/i).size.positive?
          #     @genotype.add_molecular_testing_type_strict(:predictive)
          #   else
          #     @genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip])
          #   end
          # end
          #
          # def assess_scope_from_genotype
          #   if full_screen?
          #     @genotype.add_test_scope(:full_screen)
          #   elsif targeted?
          #     @genotype.add_test_scope(:targeted_mutation)
          #   elsif ashkenazi?
          #     @genotype.add_test_scope(:aj_screen)
          #   else
          #     @genotype.add_test_scope(:no_genetictestscope)
          #   end
          # end

          # def process_tests
          #   # insert loop here
          #   @genotype_condition_extraction_methods.each do |condition_extraction|
          #     condition, extraction = *condition_extraction
          #     if send(condition)
          #       send(extraction)
          #     end
          #   end
          #   @genotypes
          # end
        end
      end
    end
  end
end
