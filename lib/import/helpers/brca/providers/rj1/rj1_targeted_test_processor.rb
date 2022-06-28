module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Processor for Targeted Screen Tests exctraction methods
          module Rj1TargetedTestProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ HERE ARE TARGETED TESTS ############################################
            #####################################################################################
            def add_targeted_screen_date
              return if @predictive_report_date.nil?

              @genotype.attribute_map['authoriseddate'] = @predictive_report_date
            end

            def positive_mlpa_brca1_targeted_test?
              return false if @brca1_mlpa_result.nil?

              ((@authoriseddate.nil? ||
              @record.raw_fields['servicereportidentifier'] == '06/03030') &&
                @brca1_mlpa_result.scan(EXON_REGEX).size.positive?) ||
                (@brca1_mlpa_result.scan(EXON_REGEX).size.positive? && targeted_test_fourth_option?)
            end

            def positive_mlpa_brca2_targeted_test?
              return false if @brca2_mlpa_result.nil?

              ((@authoriseddate.nil? ||
              @record.raw_fields['servicereportidentifier'] == '06/03030') &&
              @brca2_mlpa_result.scan(EXON_REGEX).size.positive?) ||
                (@brca2_mlpa_result.scan(EXON_REGEX).size.positive? && targeted_test_fourth_option?)
            end

            def positive_exonvariants_in_set_brca1_targeted_test?
              return false if @brca1_seq_result.nil?

              @authoriseddate.nil? && @brca1_seq_result.scan(EXON_REGEX).size.positive?
            end

            def positive_exonvariants_in_set_brca2_targeted_test?
              return false if @brca2_seq_result.nil?

              @authoriseddate.nil? && @brca2_seq_result.scan(EXON_REGEX).size.positive?
            end

            def all_null_results_targeted_test?
              @brca1_seq_result.nil? && @brca1_mutation.nil? && @brca2_mutation.nil? &&
                @brca2_seq_result.nil? && @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?
            end

            def process_all_null_results_targeted_test(test_scope)
              unknown_genotype = @genotype.dup
              unknown_genotype.add_status(4)
              unknown_genotype.add_test_scope(test_scope)
              @genotypes.append(unknown_genotype)
            end

            def process_normal_brca1_2_seq_targeted_tests
              if normal_brca12_seq_result?(@brca1_seq_result)
                process_negative_or_failed_gene('BRCA1', 1, :targeted_mutation)
              elsif normal_brca12_seq_result?(@brca2_seq_result)
                process_negative_or_failed_gene('BRCA2', 1, :targeted_mutation)
              end
              @genotypes
            end

            def normal_brca1_mlpa_targeted_test?
              return false if @brca1_mlpa_result.nil? || @brca1_mlpa_result == 'N/A'

              @brca1_mlpa_result.scan(%r{no del/dup}i).size.positive?
            end

            def normal_brca2_mlpa_targeted_test?
              return false if @brca2_mlpa_result.nil? || @brca2_mlpa_result == 'N/A'

              @brca2_mlpa_result.scan(%r{no del/dup}i).size.positive?
            end

            def process_normal_brca1_2_mlpa_targeted_tests
              if normal_brca1_mlpa_targeted_test?
                process_negative_or_failed_gene('BRCA1', 1, :targeted_mutation)
              elsif normal_brca2_mlpa_targeted_test?
                process_negative_or_failed_gene('BRCA2', 1, :targeted_mutation)
              end
              @genotypes
            end

            def process_failed_brca1_2_targeted_tests
              if failed_brca12_mlpa_targeted_test?(@brca1_mlpa_result)
                process_negative_or_failed_gene('BRCA1', 9, :targeted_mutation)
              elsif failed_brca12_mlpa_targeted_test?(@brca2_mlpa_result)
                process_negative_or_failed_gene('BRCA2', 9, :targeted_mutation)
              end
              @genotypes
            end

            def process_positive_brca1_2_seq_targeted_tests
              if positive_brca12_seq?(@brca1_seq_result)
                process_positive_cdnavariant('BRCA1', @brca1_seq_result,
                                             :targeted_mutation)
              elsif brca_mutation?(@brca1_mutation)
                process_positive_cdnavariant('BRCA1', @brca1_mutation,
                                             :targeted_mutation)
              elsif positive_brca12_seq?(@brca2_seq_result)
                process_positive_cdnavariant('BRCA2', @brca2_seq_result,
                                             :targeted_mutation)
              elsif brca_mutation?(@brca2_mutation)
                process_positive_cdnavariant('BRCA2', @brca2_mutation,
                                             :targeted_mutation)
              end
              @genotypes
            end

            def process_positive_brca1_2_mlpa_targeted_tests
              if positive_mlpa_brca1_targeted_test?
                process_positive_exonvariant('BRCA1', @brca1_mlpa_result.match(EXON_REGEX),
                                             :targeted_mutation)
              elsif positive_exonvariants_in_set_brca1_targeted_test?
                process_positive_exonvariant('BRCA1', @brca1_seq_result.match(EXON_REGEX),
                                             :targeted_mutation)
              elsif positive_mlpa_brca2_targeted_test?
                process_positive_exonvariant('BRCA2', @brca2_mlpa_result.match(EXON_REGEX),
                                             :targeted_mutation)
              elsif positive_exonvariants_in_set_brca2_targeted_test?
                process_positive_exonvariant('BRCA2', @brca2_seq_result.match(EXON_REGEX),
                                             :targeted_mutation)
              end
              @genotypes
            end

            def process_brca1_malformed_cdna_targeted_test
              return if @brca1_seq_result.nil? && @brca1_mutation.nil?

              badformat_cdna_brca1_variant = if @brca1_mutation.present?
                                               @brca1_mutation.match(MALFORMED_CDNA_REGEX)[:cdna]
                                             else
                                               @brca1_seq_result.match(MALFORMED_CDNA_REGEX)[:cdna]
                                             end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA1')
              positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';', ''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:targeted_mutation)
              @genotypes.append(positive_genotype)
            end

            def process_brca2_malformed_cdna_targeted_test
              return if @brca2_seq_result.nil? && @brca2_mutation.nil?

              badformat_cdna_brca2_variant = if @brca2_seq_result.present?
                                               @brca2_seq_result.match(MALFORMED_CDNA_REGEX)[:cdna]
                                             else
                                               @brca2_mutation.match(MALFORMED_CDNA_REGEX)[:cdna]
                                             end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA2')
              positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';', ''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:targeted_mutation)
              @genotypes.append(positive_genotype)
            end
          end
        end
      end
    end
  end
end
