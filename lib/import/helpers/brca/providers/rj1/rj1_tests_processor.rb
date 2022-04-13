module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          module Rj1TestsProcessor
            include Import::Helpers::Brca::Providers::Rj1::Rj1Constants

            #####################################################################################
            ################ OPTION METHODS ##################################################
            #####################################################################################

            def ashkenazi_test?
              @aj_report_date.present? || @aj_assay_result.present?
            end

            def polish_test?
              @polish_report_date.present? || @polish_assay_result.present?
            end

            def targeted_test_first_option?
              @predictive_report_date.present? && @aj_assay_result.nil? && @polish_assay_result.nil?
            end

            def targeted_test_second_option?
              return if @aj_assay_result.nil?
              @predictive_report_date.present? &&
              @aj_assay_result.scan(/neg|nrg/i).size.positive? &&
              (@brca1_mutation.present? || @brca2_mutation.present? ||
              @brca1_mlpa_result.present? || @brca2_mlpa_result.present?)
            end
          
            def targeted_test_third_option?
              return if @polish_assay_result.nil?
              @predictive_report_date.present? &&
              @polish_assay_result.scan(/neg|nrg/i).size.positive? &&
              (@brca1_mutation.present? || @brca2_mutation.present? ||
              @brca1_mlpa_result.present? || @brca2_mlpa_result.present?)
            end
          
            def targeted_test_fourth_option?
              return if @predictive.nil?
              @predictive_report_date.nil? && @predictive.scan(/true/i).size.positive? &&
              @ngs_result.nil? &&
              @polish_assay_result.nil? && @aj_assay_result.nil? && @fullscreen_result.nil?
            end

            def full_screen_test_option1?
              @ngs_result.present? ||
              @ngs_report_date.present?
            end

            def full_screen_test_option2?
              @fullscreen_result.present? || @authoriseddate.present?
            end

            def full_screen_test_option3?
              @predictive_report_date.nil? && @predictive.downcase == 'false' &&
              @aj_assay_result.nil? && @polish_assay_result.nil? &&
              @ngs_result.nil? && @fullscreen_result.nil? && @authoriseddate.nil?
            end
            #####################################################################################
            ################ PROCESSOR METHODS ##################################################
            #####################################################################################

            def process_ashkenazi_test
              return if @aj_assay_result.nil?
            
              add_ajscreen_date

              if normal_ashkkenazi_test?
                 process_double_brca_negative(:aj_screen)
              elsif brca1_mutation? || brca2_mutation?
                if brca1_mutation? & !brca2_mutation?
                  process_positive_cdnavariant('BRCA1',@brca1_mutation, :aj_screen)
                  process_negative_gene('BRCA2', :aj_screen)
                elsif brca2_mutation? & !brca1_mutation?
                  process_positive_cdnavariant('BRCA2',@brca2_mutation, :aj_screen)
                  process_negative_gene('BRCA1', :aj_screen)
                elsif brca2_mutation? & brca1_mutation?
                  process_positive_cdnavariant('BRCA2',@brca2_mutation, :aj_screen)
                  process_positive_cdnavariant('BRCA1',@brca1_mutation, :aj_screen)
                end
                @genotypes
              elsif brca1_mutation_exception? || @aj_assay_result == "68_69delAG"
                if @aj_assay_result == "68_69delAG"
                  process_positive_cdnavariant('BRCA1','68_69delAG', :aj_screen)
                  process_negative_gene('BRCA2', :aj_screen)
                else
                  process_positive_cdnavariant('BRCA1',@aj_assay_result, :aj_screen)
                  process_negative_gene('BRCA2', :aj_screen)
                end
                @genotypes
              elsif brca2_mutation_exception?
                 process_positive_cdnavariant('BRCA2',@aj_assay_result, :aj_screen) 
                 process_negative_gene('BRCA1', :aj_screen)
              end
              @genotypes
            end

            def process_polish_test
              return if @polish_assay_result.nil?

              add_polish_screen_date
              if normal_polish_test?
                 process_negative_gene('BRCA1', :polish_screen)
              elsif @polish_assay_result.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA1',@polish_assay_result, :polish_screen)
              end
              @genotypes
            end

            def process_targeted_test
              add_targeted_screen_date

              if all_null_results_targeted_test?
                process_all_null_results_targeted_test(:targeted_mutation)
              elsif normal_brca1_seq? || 
              normal_brca2_seq?
               process_normal_brca1_2_seq_targeted_tests
              elsif positive_seq_brca1? ||
                brca1_mutation?||
                positive_seq_brca2?||
                brca2_mutation?
                process_positive_brca1_2_seq_targeted_tests
              elsif normal_brca1_mlpa_targeted_test?||
                normal_brca2_mlpa_targeted_test?
                process_normal_brca1_2_mlpa_targeted_tests
              elsif positive_mlpa_brca1_targeted_test? ||
               positive_exonvariants_in_set_brca1_targeted_test? ||
                positive_mlpa_brca2_targeted_test? ||
                positive_exonvariants_in_set_brca2_targeted_test?
                process_positive_brca1_2_mlpa_targeted_tests
              elsif failed_brca1_mlpa_targeted_test? ||
                failed_brca2_mlpa_targeted_test?
                process_failed_brca1_2_targeted_tests
              elsif brca1_malformed_cdna_fullscreen_option3?
                process_brca1_malformed_cdna_targeted_test
              elsif brca2_malformed_cdna_fullscreen_option3?
                process_brca2_malformed_cdna_targeted_test
              elsif no_cdna_variant?
                process_all_null_results_targeted_test(:targeted_mutation)
              end
              @genotypes
            end

            def process_fullscreen_test_option1
              return if @ngs_result.nil?
              add_full_screen_date_option1
              if @ngs_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
                process_double_brca_negative(:full_screen)
              elsif @ngs_result.downcase.scan(/fail/i).size.positive?
                process_double_brca_fail(:full_screen)
              elsif @ngs_result.scan(/b(?<brca>1|2)/i).size.positive?
              
              variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
              tested_genes = @ngs_result.scan(DEPRECATED_BRCA_NAMES_REGEX).flatten.uniq.flatten.compact
              positive_genes = tested_genes.map {|tested_gene|  DEPRECATED_BRCA_NAMES_MAP[tested_gene]}
              process_multiple_variants_ngs_results(variants,positive_genes)
              #   process_multiple_variants_ngs_results(variants,positive_genes)
              elsif @ngs_result.scan(CDNA_REGEX).size > 1
                variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
                genes = @ngs_result.scan(BRCA_GENES_REGEX).uniq.flatten.compact
                process_multiple_variants_ngs_results(variants,genes)
              elsif fullscreen_brca2_mutated_cdna_brca1_normal?
                process_fullscreen_brca2_mutated_cdna_brca1_normal(@ngs_result)
              elsif fullscreen_brca1_mutated_cdna_brca2_normal?
                process_fullscreen_brca1_mutated_cdna_brca2_normal(@ngs_result)
              elsif fullscreen_brca2_mutated_exon_brca1_normal?
                process_fullscreen_brca2_mutated_exon_brca1_normal(@ngs_result.match(EXON_REGEX))
              elsif fullscreen_brca1_mutated_exon_brca2_normal?
                process_fullscreen_brca1_mutated_exon_brca2_normal(@ngs_result.match(EXON_REGEX))
              elsif fullscreen_non_brca_mutated_cdna_gene?
                process_fullscreen_non_brca_mutated_cdna_gene
              elsif fullscreen_non_brca_mutated_exon_gene?
                process_fullscreen_non_brca_mutated_exon_gene
              elsif @ngs_result.scan(BRCA_GENES_REGEX).size.positive? &&
                @ngs_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
                positive_genotype = @genotype.dup
                positive_gene = @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact.join
                negative_gene = ["BRCA2", "BRCA1"] - @ngs_result.scan(BRCA_GENES_REGEX).flatten.compact
                process_negative_gene(negative_gene.join, :full_screen)
                positive_genotype.add_gene(positive_gene)
                positive_genotype.add_gene_location(@ngs_result.match(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i)[:cdna].tr(';',''))
                positive_genotype.add_status(2)
                positive_genotype.add_test_scope(:full_screen)
                @genotypes.append(positive_genotype)
              end
            end

            def process_fullscreen_test_option2
            
              add_full_screen_date_option2
              if @fullscreen_result.present? && @fullscreen_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
                process_double_brca_negative(:full_screen)
              elsif fullscreen_non_brca_mutated_cdna_gene?
                process_fullscreen_non_brca_mutated_cdna_gene
              elsif brca1_mutation? && brca2_mutation?
                process_positive_cdnavariant('BRCA1', @brca1_mutation, :full_screen)
                process_positive_cdnavariant('BRCA2', @brca2_mutation, :full_screen)
              elsif brca2_cdna_variant_fullscreen_option2?
                process_fullscreen_brca2_mutated_cdna_option2
              elsif brca1_cdna_variant_fullscreen_option2?
                process_fullscreen_brca1_mutated_cdna_option2
              elsif all_null_cdna_variants_except_full_screen_test?
                process_fullscreen_result_cdnavariant
              elsif fullscreen_brca1_mlpa_positive_variant?
                process_full_screen_brca1_mlpa_positive_variant(@brca1_mlpa_result.scan(EXON_REGEX))
              elsif fullscreen_brca2_mlpa_positive_variant?
                process_full_screen_brca2_mlpa_positive_variant(@brca2_mlpa_result.scan(EXON_REGEX))
              elsif all_fullscreen_option2_relevant_fields_nil?
                process_double_brca_unknown(:full_screen)
              elsif double_brca_mlpa_negative?
                process_double_brca_negative(:full_screen)
              elsif brca1_mlpa_normal_brca2_null?
                process_double_brca_fail(:full_screen)
              end
            end

            def process_fullscreen_test_option3
              add_full_screen_date_option3
             if all_fullscreen_option2_relevant_fields_nil?
               process_double_brca_unknown(:full_screen)
             elsif brca1_normal_brca2_nil? || brca2_normal_brca1_nil?
               process_double_brca_negative(:full_screen)
             elsif brca_false_positives?
               process_double_brca_negative(:full_screen)
             elsif normal_brca2_malformed_fullscreen_option3?
               process_double_brca_negative(:full_screen)
             elsif brca1_malformed_cdna_fullscreen_option3?
               process_brca1_malformed_cdna_fullscreen_option3
             elsif brca2_malformed_cdna_fullscreen_option3?
               process_brca2_malformed_cdna_fullscreen_option3
             elsif brca1_cdna_variant_fullscreen_option3?
               process_brca1_cdna_variant_fullscreen_option3
             elsif brca2_cdna_variant_fullscreen_option3?
               process_brca2_cdna_variant_fullscreen_option3
             elsif double_brca_mlpa_negative?
               process_double_brca_negative(:full_screen)
             elsif fullscreen_brca1_mlpa_positive_variant?
               process_full_screen_brca1_mlpa_positive_variant(@brca1_mlpa_result.scan(EXON_REGEX))
             elsif fullscreen_brca2_mlpa_positive_variant?
               process_full_screen_brca2_mlpa_positive_variant(@brca2_mlpa_result.scan(EXON_REGEX))
             elsif double_brca_malformed_cdna_fullscreen_option3?
               process_double_brca_malformed_cdna_fullscreen_option3
             elsif @brca2_mlpa_result.present? && @brca1_mlpa_result.present? &&
               @brca2_mlpa_result.scan(/fail/i).size.positive? &&
               @brca1_mlpa_result.scan(/fail/i).size.positive? &&
               process_double_brca_fail(:full_screen)
             elsif brca1_mlpa_normal_brca2_null?
               process_double_brca_fail(:full_screen)
             end
            end

          end
        end
      end
    end
  end
end
