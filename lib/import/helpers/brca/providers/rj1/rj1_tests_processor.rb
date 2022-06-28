module Import
  module Helpers
    module Brca
      module Providers
        module Rj1
          # Extraction processor for Full Screen, Targeted, Ashkenazi and Polish tests
          # rubocop:disable Metrics/ModuleLength
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
              return false if @aj_assay_result.nil?

              @predictive_report_date.present? &&
                @aj_assay_result.scan(/neg|nrg/i).size.positive? &&
                (@brca1_mutation.present? || @brca2_mutation.present?)
            end

            def targeted_test_third_option?
              return false if @polish_assay_result.nil?

              @predictive_report_date.present? &&
                @polish_assay_result.scan(/neg|nrg/i).size.positive? &&
                (@brca1_mutation.present? || @brca2_mutation.present? ||
                @brca1_mlpa_result.present? || @brca2_mlpa_result.present?)
            end

            def targeted_test_fourth_option?
              return false if @predictive.nil?

              @predictive_report_date.nil? && @predictive.scan(/true/i).size.positive? &&
                @ngs_result.nil? &&
                @polish_assay_result.nil? && @aj_assay_result.nil? && @fullscreen_result.nil?
            end

            def full_screen_test_option1?
              @ngs_result.present? || @ngs_report_date.present?
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

            # rubocop:disable Metrics/AbcSize
            # rubocop:disable  Metrics/CyclomaticComplexity
            # rubocop:disable Metrics/MethodLength
            def process_ashkenazi_test
              return if @aj_assay_result.nil?

              add_ajscreen_date

              if normal_ashkkenazi_test?
                process_double_brca_status(1, :aj_screen)
              elsif brca_mutation?(@brca1_mutation) || brca_mutation?(@brca2_mutation)
                if brca_mutation?(@brca1_mutation) & !brca_mutation?(@brca2_mutation)
                  process_positive_cdnavariant('BRCA1', @brca1_mutation, :aj_screen)
                  process_negative_or_failed_gene('BRCA2', 1, :aj_screen)
                elsif brca_mutation?(@brca2_mutation) & !brca_mutation?(@brca1_mutation)
                  process_positive_cdnavariant('BRCA2', @brca2_mutation, :aj_screen)
                  process_negative_or_failed_gene('BRCA1', 1, :aj_screen)
                end
              elsif brca1_mutation_exception? || @aj_assay_result == '68_69delAG'
                process_positive_cdnavariant('BRCA1', @aj_assay_result, :aj_screen)
                process_negative_or_failed_gene('BRCA2', 1, :aj_screen)
              elsif brca2_mutation_exception?
                process_positive_cdnavariant('BRCA2', @aj_assay_result, :aj_screen)
                process_negative_or_failed_gene('BRCA1', 1, :aj_screen)
              end
              @genotypes
            end
            # rubocop:enable Metrics/MethodLength

            # rubocop:enable Metrics/AbcSize
            # rubocop:enable  Metrics/CyclomaticComplexity
            def process_polish_test
              return if @polish_assay_result.nil?

              add_polish_screen_date
              if normal_polish_test?
                process_negative_or_failed_gene('BRCA1', 1, :polish_screen)
              elsif @polish_assay_result.scan(CDNA_REGEX).size.positive?
                process_positive_cdnavariant('BRCA1', @polish_assay_result, :polish_screen)
              end
              @genotypes
            end

            # rubocop:disable Lint/DuplicateBranch
            # rubocop:disable Metrics/AbcSize
            # rubocop:disable  Metrics/CyclomaticComplexity
            # rubocop:disable  Metrics/MethodLength
            # rubocop:disable  Metrics/PerceivedComplexity
            def process_targeted_test
              add_targeted_screen_date

              if all_null_results_targeted_test?
                process_all_null_results_targeted_test(:targeted_mutation)
              elsif normal_brca12_seq_result?(@brca1_seq_result) ||
                    normal_brca12_seq_result?(@brca2_seq_result)
                process_normal_brca1_2_seq_targeted_tests
              elsif positive_brca12_seq?(@brca1_seq_result) ||
                    brca_mutation?(@brca1_mutation) ||
                    positive_brca12_seq?(@brca2_seq_result) ||
                    brca_mutation?(@brca2_mutation)
                process_positive_brca1_2_seq_targeted_tests
              elsif normal_brca1_mlpa_targeted_test? ||
                    normal_brca2_mlpa_targeted_test?
                process_normal_brca1_2_mlpa_targeted_tests
              elsif failed_brca12_mlpa_targeted_test?(@brca1_mlpa_result) ||
                    failed_brca12_mlpa_targeted_test?(@brca2_mlpa_result)
                process_failed_brca1_2_targeted_tests
              elsif positive_mlpa_brca1_targeted_test? ||
                    positive_exonvariants_in_set_brca1_targeted_test? ||
                    positive_mlpa_brca2_targeted_test? ||
                    positive_exonvariants_in_set_brca2_targeted_test?
                process_positive_brca1_2_mlpa_targeted_tests

              elsif brca1_malformed_cdna_fullscreen_option3?
                process_brca1_malformed_cdna_targeted_test
              elsif brca2_malformed_cdna_fullscreen_option3?
                process_brca2_malformed_cdna_targeted_test
              elsif no_cdna_variant?
                process_all_null_results_targeted_test(:targeted_mutation)
              end
              @genotypes
            end
            # rubocop:enable Lint/DuplicateBranch
            # rubocop:enable Metrics/AbcSize
            # rubocop:enable  Metrics/CyclomaticComplexity
            # rubocop:enable  Metrics/MethodLength
            # rubocop:enable  Metrics/PerceivedComplexity

            # rubocop:disable Metrics/AbcSize
            # rubocop:disable  Metrics/CyclomaticComplexity
            # rubocop:disable  Metrics/MethodLength
            # rubocop:disable  Metrics/PerceivedComplexity
            def process_fullscreen_test_option1
              return if @ngs_result.nil?

              add_full_screen_date_option1
              if @ngs_result.downcase.scan(/no\s*mut|no\s*var/i).size.positive?
                process_double_brca_status(1, :full_screen)
              elsif @ngs_result.downcase.scan(/fail/i).size.positive?
                process_double_brca_status(9, :full_screen)
              elsif @ngs_result.scan(CDNA_REGEX).size > 1 &&
                    @ngs_result.scan(BRCA_GENES_REGEX).present?
                variants = @ngs_result.scan(CDNA_REGEX).uniq.flatten.compact
                genes = @ngs_result.scan(BRCA_GENES_REGEX).uniq.flatten.compact
                process_multiple_variants_fullscreen_results(variants, genes)
              elsif fullscreen_non_brca_mutated_cdna_gene?
                process_fullscreen_non_brca_mutated_cdna_gene
              elsif @ngs_result.scan(/PALB2|CHECK2/i).size.positive? &&
                    @ngs_result.scan(EXON_REGEX).size.positive?
                process_fullscreen_nonbrca_mutated_exon(@ngs_result.match(EXON_REGEX))
              elsif @ngs_result.scan(/b(?<brca>1|2)/i).size.positive?
                process_deprecated_genes_record_fullscreen_option1
              elsif fullscreen_brca2_mutated_cdna_brca1_normal?
                process_fullscreen_brca2_mutated_cdna_brca1_normal(@ngs_result)
              elsif fullscreen_brca1_mutated_cdna_brca2_normal?
                process_fullscreen_brca1_mutated_cdna_brca2_normal(@ngs_result)
              elsif fullscreen_brca2_mutated_exon_brca1_normal?
                process_fullscreen_brca2_mutated_exon_brca1_normal(@ngs_result.match(EXON_REGEX))
              elsif fullscreen_brca1_mutated_exon_brca2_normal?
                process_fullscreen_brca1_mutated_exon_brca2_normal(@ngs_result.match(EXON_REGEX))
              elsif @ngs_result.scan(BRCA_GENES_REGEX).size.positive? &&
                    @ngs_result.scan(/(?<cdna>[0-9]+[a-z]+>[a-z]+)/i).size.positive?
                process_malformed_variants_fullscreen_option1
              elsif @ngs_result.scan(/1100del/i).size.positive?
                process_adhoc_chek2_fullscreen_positive_records
              end
            end
            # rubocop:enable Metrics/AbcSize
            # rubocop:enable  Metrics/CyclomaticComplexity
            # rubocop:enable  Metrics/MethodLength
            # rubocop:enable  Metrics/PerceivedComplexity

            # rubocop:disable Lint/DuplicateBranch
            # rubocop:disable Metrics/AbcSize
            # rubocop:disable  Metrics/CyclomaticComplexity
            # rubocop:disable  Metrics/MethodLength
            # rubocop:disable  Metrics/PerceivedComplexity
            def process_fullscreen_test_option2
              add_full_screen_date_option2
              if @fullscreen_result.present? &&
                 @fullscreen_result.downcase.scan(/no\s*mut|no\s*var|norm/i).size.positive?
                process_double_brca_status(1, :full_screen)
              elsif brca1_malformed_cdna_fullscreen_option3?
                process_brca1_malformed_cdna_fullscreen_option3
              elsif brca2_malformed_cdna_fullscreen_option3?
                process_brca2_malformed_cdna_fullscreen_option3
              elsif brca_mutation?(@brca1_mutation) && brca_mutation?(@brca2_mutation)
                process_positive_cdnavariant('BRCA1', @brca1_mutation, :full_screen)
                process_positive_cdnavariant('BRCA2', @brca2_mutation, :full_screen)
              elsif brca2_cdna_variant_fullscreen_option2?
                process_fullscreen_brca2_mutated_cdna_option2
              elsif brca1_cdna_variant_fullscreen_option2?
                process_fullscreen_brca1_mutated_cdna_option2
              elsif all_null_cdna_variants_except_full_screen_test?
                process_fullscreen_result_cdnavariant
              elsif fullscreen_brca1_mlpa_positive_variant?
                process_full_screen_brca1_mlpa_positive_variant(
                  @brca1_mlpa_result.match(EXON_REGEX)
                )
              elsif fullscreen_brca2_mlpa_positive_variant?
                # TODO: Check the method below
                process_full_screen_brca2_mlpa_positive_variant(
                  @brca2_mlpa_result.match(EXON_REGEX)
                )
              elsif all_fullscreen_option2_relevant_fields_nil?
                process_double_brca_status(1, :full_screen)
              elsif double_brca_mlpa_negative?
                process_double_brca_status(1, :full_screen)
              elsif brca12_mlpa_normal_brca12_null?
                process_double_brca_status(1, :full_screen)
              end
            end
            # rubocop:enable Lint/DuplicateBranch
            # rubocop:enable Metrics/AbcSize
            # rubocop:enable  Metrics/CyclomaticComplexity
            # rubocop:enable  Metrics/MethodLength
            # rubocop:enable  Metrics/PerceivedComplexity

            # rubocop:disable Lint/DuplicateBranch
            # rubocop:disable Metrics/AbcSize
            # rubocop:disable  Metrics/CyclomaticComplexity
            # rubocop:disable  Metrics/MethodLength
            # rubocop:disable  Metrics/PerceivedComplexity
            def process_fullscreen_test_option3
              add_full_screen_date_option3
              if all_fullscreen_option2_relevant_fields_nil?
                process_double_brca_status(4, :full_screen)
              elsif brca1_normal_brca2_nil? || brca2_normal_brca1_nil?
                process_double_brca_status(1, :full_screen)
              elsif brca_false_positives?
                process_double_brca_status(1, :full_screen)
              elsif normal_brca2_malformed_fullscreen_option3?
                process_double_brca_status(1, :full_screen)
              elsif brca1_malformed_cdna_fullscreen_option3?
                process_brca1_malformed_cdna_fullscreen_option3
              elsif brca2_malformed_cdna_fullscreen_option3?
                process_brca2_malformed_cdna_fullscreen_option3
              elsif brca1_cdna_variant_fullscreen_option3?
                process_brca1_cdna_variant_fullscreen_option3
              elsif brca2_cdna_variant_fullscreen_option3?
                process_brca2_cdna_variant_fullscreen_option3
              elsif double_brca_mlpa_negative?
                process_double_brca_status(1, :full_screen)
              elsif fullscreen_brca1_mlpa_positive_variant?
                process_full_screen_brca1_mlpa_positive_variant(
                  @brca1_mlpa_result.match(EXON_REGEX)
                )
              elsif fullscreen_brca2_mlpa_positive_variant?
                process_full_screen_brca2_mlpa_positive_variant(
                  @brca2_mlpa_result.match(EXON_REGEX)
                )
              elsif double_brca_malformed_cdna_fullscreen_option3?
                process_double_brca_malformed_cdna_fullscreen_option3
              elsif @brca2_mlpa_result.present? && @brca1_mlpa_result.present? &&
                    @brca2_mlpa_result.scan(/fail/i).size.positive? &&
                    @brca1_mlpa_result.scan(/fail/i).size.positive?
                process_double_brca_status(9, :full_screen)
              elsif brca12_mlpa_normal_brca12_null?
                process_double_brca_status(1, :full_screen)
              end
            end
            # rubocop:enable Lint/DuplicateBranch
            # rubocop:enable Metrics/AbcSize
            # rubocop:enable  Metrics/CyclomaticComplexity
            # rubocop:enable  Metrics/MethodLength
            # rubocop:enable  Metrics/PerceivedComplexity
          end
          # rubocop:enable Metrics/ModuleLength
        end
      end
    end
  end
end
