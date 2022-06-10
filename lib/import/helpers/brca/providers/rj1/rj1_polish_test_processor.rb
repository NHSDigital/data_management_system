module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Processor for Polish Tests exctraction methods
          module Rj1PolishTestProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ HERE ARE POLISH TESTS ##############################################
            #####################################################################################
            def add_polish_screen_date
              return if @polish_report_date.nil?

              @genotype.attribute_map['authoriseddate'] = @polish_report_date
            end

            def polish_test?
              @polish_report_date.present? || @polish_assay_result.present?
            end

            def normal_polish_test?
              @polish_assay_result.downcase == 'mutation not detected' ||
                @polish_assay_result.downcase == 'neg' ||
                @polish_assay_result.downcase == 'nrg' ||
                @polish_assay_result.downcase == 'no mutation' ||
                @polish_assay_result.downcase == 'no mutations' ||
                @polish_assay_result.downcase == 'no variant' ||
                @polish_assay_result.downcase == 'no variants detected' ||
                @polish_assay_result.scan(/neg|nrg/i).size.positive?
            end
          end
        end
      end
    end
  end
end
