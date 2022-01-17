module Import
  module Helpers
    module Brca
      module Providers
        module Rr8
          module Rr8ReportCases
            include Import::Helpers::Brca::Providers::Rr8::Rr8Constants

            def full_screen?
              return if @genetictestscope_field.nil?

              FULL_SCREEN_LIST.include?(@genetictestscope_field.downcase.to_s) ||
              @genetictestscope_field.downcase.scan(FULL_SCREEN_REGEX).size.positive?
            end

            def targeted?
              return if @genetictestscope_field.nil?

              (TARGETED_LIST.include?(@genetictestscope_field.downcase.to_s) ||
              @genetictestscope_field.downcase.scan(TARGETED_REGEX).size.positive?) && 
              (@genotype_string.scan(AJNEGATIVE_REGEX).size.zero? &&
              @genotype_string.scan(AJPOSITIVE_REGEX).size.zero?)
            end

            def ashkenazi?
              return if @genetictestscope_field.nil?

              (@genetictestscope_field.downcase.include? ('ashkenazi') or
              @genetictestscope_field.include?('AJ')) ||
              (@genotype_string.downcase.include? ('ashkenazi') or
              @genotype_string.include?('AJ'))
            end

            def familial_class_record?
              @genotype_string.scan(/Familial Class/i.freeze).size.positive?
            end

            def brca2_pttshift_record?
              @genotype_string == 'B2 PTT shift'
            end

            def class_3_unaffected_records?
              @genotype_string == 'Class 3 - UNAFFECTED'
            end

            def b1_mlpa_exon_positive?
              @genotype_string.scan(/B1.+MLPA\+ve/).size.positive?
            end

            def predictive_test_exon13?
              @genotype_string.scan(/Predictive Ex13 dup (?<negpos>neg|pos)/i).size.positive?
            end

            def class4_negative_predictive?
              @genotype_string == 'Pred Class 4 seq negative'
            end

            def class_m_record?
              @genotype_string.scan(CLASS_M_REGEX).size.positive?
            end

            def predictive_test?
              @genotype_string.scan(PREDICTIVE_VALID_REGEX).size.positive?
            end

            def word_report_test?
              @genotype_string.scan(WORD_REPORT_NORMAL_REGEX).size.positive?
            end

            def mlpa_negative_screening_failed?
              @genotype_string == 'screening failed; MLPA normal'
            end

            def brca_diagnostic_normal?
              @genotype_string == 'BRCA - Diagnostic Normal'
            end

            def screening_failed?
              @genotype_string.downcase == 'screening failed'
            end

            def brca_diagnostic_test?
              @genotype_string.scan(/BRCA\s\-\sDiagnostic/).size.positive?
            end

            def pred_class4_positive_records?
              @genotype_string.scan(/Pred Class 4 seq pos/).size.positive?
            end

            def brca_diag_tests?
              @genotype_string.scan(/BRCA\sMS.+Diag\s(?<negpos>Normal|
                                     Diag\sC4\/5)/ix).size.positive?
            end

            def predictive_b2_pathological_neg_test?
              @genotype_string == 'Pred B2 C4/C5 seq neg'
            end

            def ngs_failed_mlpa_normal_test?
              @genotype_string == 'NGS failed; MLPA normal'
            end

            def brca_palb2_diag_class4_5_tests?
              @genotype_string == 'BRCA/PALB2 - Diag C4/5' ||
              @genotype_string == 'BRCA/PALB2 Diag C4/5 - UNAFF'
            end

            def brca_palb2_mlpa_class4_5_tests?
              @genotype_string == 'BRCA/PALB2 - Diag C4/5 MLPA'
            end

            def brca_diag_class4_5_mlpa_tests?
              @genotype_string == 'BRCA MS Diag C4/C5 - MLPA'
            end

            def brca_palb2_diag_screening_failed_test?
              @genotype_string == 'BRCA/PALB2 Diag screening failed'
            end

            def ngs_screening_failed_tests?
              @genotype_string == 'NGS screening failed'
            end

            def ngs_B1_and_B2_normal_mlpa_fail?
              @genotype_string == 'NGS B1 and B2 normal, MLPA fail'
            end
            
            def brca_palb2_diag_normal_test?
              @genotype_string == 'BRCA/PALB2 - Diag Normal' ||
              @genotype_string == 'BRCA/PALB2 Diag Normal - UNAFF'
            end

            def ngs_brca2_multiple_exon_mlpa_positive?
              @genotype_string == 'NGS B2(multiple exon)MLPA+ve'
            end

            def brca2_class3_unknown_variant_test?
              @genotype_string == 'B2 Class 3b UV'
            end

            def mlpa_only_fail_test?
              @genotype_string == 'MLPA only fail'
            end

            def generic_normal_test?
              @genotype_string == 'Generic normal'
            end

            def brca_diagnostic_class4_5_test?
              @genotype_string == 'BRCA MS - Diag C4/5'
            end

            def brca_diagnostic_class3?
              @genotype_string == 'BRCA MS - Diag C3'
            end

            def brca_palb2_diagnostic_class3_test?
              @genotype_string == 'BRCA/PALB2 - Diag C3 UNAFF' ||
              @genotype_string == 'BRCA/PALB2 - Diag C3'
            end

            def ashkenazi_test?
              @genotype_string.scan(AJNEGATIVE_REGEX).size.positive? ||
              @genotype_string.scan(AJPOSITIVE_REGEX).size.positive? ||
              (@genotype_string.downcase.include? ('ashkenazi') or
              @genotype_string.include?('AJ'))
            end

            def truncating_variant_test?
              @genotype_string.scan(TRUNCATING_VARIANT_REGEX).size.positive?
            end

            def double_normal_test?
              words = @genotype_string.split(/,| |\//) 
              trimmed_words = words.map(&:downcase).
                              reject { |x| DOUBLE_NORMAL_EXCLUDEABLE.include? x }
              all_safe = trimmed_words.
                         reject { |x| DOUBLE_NORMAL_LIST.include? x }.
                         empty? # TODO: flag/error if false?
              all_present = trimmed_words.include?('b1') &&
                            trimmed_words.include?('b2') &&
                            (trimmed_words.include?('normal') ||
                            trimmed_words.include?('unaffected'))
              all_safe && all_present
            end

            def double_normal_test_mlpa_fail?
              @genotype_string.scan(DOUBLE_NORMAL_MLPA_FAIL).size.positive?
            end

            def variant_seq?
              @genotype_string.scan(VARIANTSEQ_REGEX).size.positive?
            end

            def variant_class?
              @genotype_string.scan(VARIANT_CLASS_REGEX).size.positive?
            end

            def confirmation_test?
              @genotype_string.scan(CONFIRMATION_REGEX).size.positive?
            end
          end
        end
      end
    end
  end
end
