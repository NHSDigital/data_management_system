module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details into generalized internal genotype format
        class VariantProcessor
          include Import::Helpers::Brca::Providers::Rr8::Rr8Constants
          include Import::Helpers::Brca::Providers::Rr8::Rr8Helper
          include Import::Helpers::Brca::Providers::Rr8::Rr8ReportCases
          
          attr_accessor :report_string
          attr_accessor :genotype_string
          attr_accessor :genetictestscope_field
          
          
          def initialize(genotype, record, logger)
            @genotype   = genotype
            @record     = record
            @logger     = logger
            @genotypes  = []
            @genetictestscope_field = Maybe([record.raw_fields['reason'],
                                            record.raw_fields['moleculartestingtype']].
                                            reject(&:nil?).first).or_else('')
            @genotype_string = Maybe(record.raw_fields['genotype']).
                                     or_else(Maybe(record.raw_fields['report_result']).
                                     or_else(''))
            @report_string = Maybe([record.raw_fields['report'],
                                   record.mapped_fields['report'],
                                   record.raw_fields['firstofreport']].
                                   reject(&:nil?).first).or_else('')
          end

          def assess_scope_from_genotype
            if full_screen?
              @genotype.add_test_scope(:full_screen)
            elsif targeted?
              @genotype.add_test_scope(:targeted_mutation)
            elsif ashkenazi?
              @genotype.add_test_scope(:aj_screen)
            else
              @genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_tests
            if predictive_test?
              process_predictive_tests
            elsif double_normal_test?
              brca_double_negative
              # process_doublenormal_tests
            elsif variant_seq?
              process_variantseq_tests
            elsif variant_class?
              process_variant_class_records
            elsif confirmation_test?
              process_confirmation_test
            elsif ashkenazi_test?
              process_ashkenazi_tests
            elsif double_normal_test_mlpa_fail?
              process_double_normal_mlpa_test
            elsif truncating_variant_test?
              process_truncating_variant_test
            elsif word_report_test?
              process_word_report_tests
            elsif class_m_record?
              process_class_m_tests
            elsif familial_class_record?
              process_familial_class_tests
            elsif class4_negative_predictive?
              process_class4_pred_neg_record
            elsif brca2_pttshift_record?
              process_brca2_pttshift_records
            elsif b1_mlpa_exon_positive?
              process_b1_mlpa_exon_positive
            elsif mlpa_negative_screening_failed?
              brca_double_negative
              # process_mlpa_negative_screening_failed
            elsif brca_diagnostic_normal?
              brca_double_negative
              # process_brca_diagnostic_normal
            elsif predictive_test_exon13?
              process_predictive_test_exon13
            elsif screening_failed?
              process_screening_failed_records
            elsif brca_diagnostic_test?
              process_brca_diagnostic_tests
            elsif class_3_unaffected_records?
              process_class_3_unaffected_records
            elsif pred_class4_positive_records?
              process_pred_class4_positive_records
            elsif brca_diag_tests?
              brca_double_negative
            elsif predictive_b2_pathological_neg_test?
              process_predictive_b2_pathological_neg_record
            elsif ngs_failed_mlpa_normal_test?
              brca_double_negative
            elsif ngs_screening_failed_tests?
              process_ngs_screening_failed_record
            elsif ngs_B1_and_B2_normal_mlpa_fail?
              brca_double_negative
            elsif brca_palb2_diag_normal_test?
              process_brca_palb2_diag_normal_record
            elsif ngs_brca2_multiple_exon_mlpa_positive?
              process_ngs_brca2_multiple_exon_mlpa_positive?
            elsif brca2_class3_unknown_variant_test?
              process_brca2_class3_unknown_variant_records
            elsif mlpa_only_fail_test?
              process_mlpa_only_fail_record
            elsif brca_palb2_diagnostic_class3_test?
              process_brca_palb2_diagnostic_class3_record
            elsif generic_normal_test?
              process_generic_normal_record
            elsif brca_palb2_diag_class4_5_tests?
              process_brca_palb2_diag_class4_5_record
            elsif brca_diagnostic_class4_5_test?
              process_brca_diagnostic_class4_5_record
            elsif brca_palb2_mlpa_class4_5_tests?
              process_brca_palb2_mlpa_class4_5_record
            elsif brca_diag_class4_5_mlpa_tests?
              process_brca_diag_class4_5_mlpa_record
            elsif brca_diagnostic_class3?
              process_brca_diagnostic_class3_record
            elsif brca_palb2_diag_screening_failed_test?
              process_brca_palb2_diag_screening_failed_record
            end
            @genotypes
          end
        end
      end
    end
  end
end
