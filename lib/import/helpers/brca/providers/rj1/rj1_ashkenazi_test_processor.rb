module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Processor for Ashkenazi Screen Tests exctraction methods
          module Rj1AshkenaziTestProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ HERE ARE ASHKENAZI TESTS ###########################################
            #####################################################################################

            def add_ajscreen_date
              return if @aj_report_date.nil? && @report_report_date.nil?

              if @aj_report_date.present?
                @genotype.attribute_map['authoriseddate'] = @aj_report_date
              elsif @report_report_date.present?
                @genotype.attribute_map['authoriseddate'] = @predictive_report_date
              end
            end

            def normal_ashkenazi_test?
              return false if @aj_assay_result.nil?

              @aj_assay_result.scan(/neg|nrg/i).size.positive? &&
                @brca1_mutation.nil? && @brca2_mutation.nil?
            end

            def positive_ashkenazi_test?
              return false if @aj_assay_result.nil?

              @aj_assay_result.scan(/neg|nrg/i).size.zero?
            end

            def normal_ashkkenazi_test?
              @aj_assay_result.downcase == 'mutation not detected' ||
                @aj_assay_result.downcase == 'neg' ||
                @aj_assay_result.downcase == 'nrg' ||
                @aj_assay_result.downcase == 'no mutation' ||
                @aj_assay_result.downcase == 'no variant' ||
                @aj_assay_result.downcase == 'no variants detected' ||
                @aj_assay_result.scan(/neg|nrg/i).size.positive?
            end

            def brca1_mutation_exception?
              BRCA1_MUTATIONS.include? @aj_assay_result
            end

            def brca2_mutation_exception?
              BRCA2_MUTATIONS.include? @aj_assay_result
            end
          end
        end
      end
    end
  end
end
