module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
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
              return if @brca1_mlpa_result.nil?
              (@authoriseddate.nil? || @record.raw_fields['servicereportidentifier'] == '06/03030') &&
              @brca1_mlpa_result.scan(EXON_REGEX).size.positive?
            end

            def positive_mlpa_brca2_targeted_test?
              return if @brca2_mlpa_result.nil?
              (@authoriseddate.nil? || @record.raw_fields['servicereportidentifier'] == '06/03030') &&
              @brca2_mlpa_result.scan(EXON_REGEX).size.positive?
            end

            def positive_exonvariants_in_set_brca1_targeted_test?
              return if @brca1_seq_result.nil?
              @authoriseddate.nil? && @brca1_seq_result.scan(EXON_REGEX).size.positive?
            end

            def positive_exonvariants_in_set_brca2_targeted_test?
              return if @brca2_seq_result.nil?
              @authoriseddate.nil? && @brca2_seq_result.scan(EXON_REGEX).size.positive?
            end

            def all_null_results_targeted_test?
              @brca1_seq_result.nil? && @brca2_seq_result.nil? &&
              @brca1_mpa_result.nil? && @brca2_mlpa_result.nil?
            end
          
          
            def process_all_null_results_targeted_test(test_scope)
              unknown_genotype = @genotype.dup
              unknown_genotype.add_status(9)
              unknown_genotype.add_test_scope(test_scope)
              @genotypes.append(unknown_genotype)
            end
          
            def process_normal_brca1_2_seq_targeted_tests
              if normal_brca1_seq?
                process_negative_gene('BRCA1', :targeted_mutation)
              elsif normal_brca2_seq?
                process_negative_gene('BRCA2', :targeted_mutation)
              end
              @genotypes
            end

            def process_normal_brca1_2_mlpa_targeted_tests
              if normal_brca1_mlpa_targeted_test?
                process_negative_gene('BRCA1', :targeted_mutation)
              elsif normal_brca2_mlpa_targeted_test?
                process_negative_gene('BRCA2', :targeted_mutation)
              end
              @genotypes
            end
          
            def process_failed_brca1_2_targeted_tests
              if failed_brca1_mlpa_targeted_test?
                process_failed_gene('BRCA1', :targeted_mutation)
              elsif failed_brca1_mlpa_targeted_test?
                process_failed_gene('BRCA2', :targeted_mutation)
              end
              @genotypes
            end

            def process_positive_brca1_2_seq_targeted_tests
              if positive_seq_brca1?
                process_positive_cdnavariant('BRCA1',@brca1_seq_result, 
                                           :targeted_mutation)
              elsif brca1_mutation?
                process_positive_cdnavariant('BRCA1',@brca1_mutation, 
                                              :targeted_mutation)
              elsif positive_seq_brca2?
                process_positive_cdnavariant('BRCA2',@brca2_seq_result, 
                                          :targeted_mutation)
              elsif brca2_mutation?
                process_positive_cdnavariant('BRCA2',@brca2_mutation, 
                                              :targeted_mutation)
              end
              @genotypes
            end
          
            def process_positive_brca1_2_mlpa_targeted_tests
              return if @brca1_mlpa_result.nil? && @brca2_mlpa_result.nil?

              if positive_mlpa_brca1_targeted_test?
                process_positive_exonvariant('BRCA1', @brca1_mlpa_result.match(EXON_REGEX), :targeted_mutation)
              elsif positive_exonvariants_in_set_brca1_targeted_test?
                 process_positive_exonvariant('BRCA1', @brca1_seq_result.match(EXON_REGEX), :targeted_mutation)
              elsif positive_mlpa_brca2_targeted_test?
                process_positive_exonvariant('BRCA2', @brca2_mlpa_result.match(EXON_REGEX), :targeted_mutation)
              elsif positive_exonvariants_in_set_brca2_targeted_test?
                process_positive_exonvariant('BRCA2', @brca2_seq_result.match(EXON_REGEX), :targeted_mutation)
              end
              @genotypes
            end
          
            def process_brca1_malformed_cdna_targeted_test
              return if @brca1_seq_result.nil? && @brca1_mutation.nil?
              if @brca1_seq_result.present?
                badformat_cdna_brca1_variant = @brca1_seq_result.scan(/([^\s]+)/i)[0].join
              else badformat_cdna_brca1_variant = @brca1_mutation.scan(/([^\s]+)/i)[0].join
              end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA1')
              positive_genotype.add_gene_location(badformat_cdna_brca1_variant.tr(';',''))
              positive_genotype.add_status(2)
              positive_genotype.add_test_scope(:targeted_mutation)
              @genotypes.append(positive_genotype)
            end

            def process_brca2_malformed_cdna_targeted_test
              return if @brca2_seq_result.nil? && @brca2_mutation.nil?
              if @brca2_seq_result.present?
                badformat_cdna_brca2_variant = @brca2_seq_result.scan(/([^\s]+)/i)[0].join
              else badformat_cdna_brca2_variant = @brca2_mutation.scan(/([^\s]+)/i)[0].join
              end
              positive_genotype = @genotype.dup
              positive_genotype.add_gene('BRCA2')
              positive_genotype.add_gene_location(badformat_cdna_brca2_variant.tr(';',''))
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
