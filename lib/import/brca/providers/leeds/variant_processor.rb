module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details
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
            @genotype_condition_extraction_methods = [
              [:predictive_test?, :process_predictive_tests],
              [:double_normal_test?, :brca_double_negative],
              [:variant_seq?, :process_variantseq_tests],
              [:variant_class?, :process_variant_class_records],
              [:confirmation_test?, :process_confirmation_test],
              [:ashkenazi_test?, :process_ashkenazi_tests],
              [:double_normal_test_mlpa_fail?, :process_double_normal_mlpa_test],
              [:truncating_variant_test?, :process_truncating_variant_test],
              [:word_report_test?, :process_word_report_tests],
              [:class_m_record?, :process_class_m_tests],
              [:familial_class_record?, :process_familial_class_tests],
              [:class4_negative_predictive?, :process_class4_negative_predictive],
              [:brca2_pttshift_record?, :process_brca2_pttshift_records],
              [:b1_mlpa_exon_positive?, :process_b1_mlpa_exon_positive],
              [:mlpa_negative_screening_failed?, :brca_double_negative],
              [:predictive_test_exon13?, :process_predictive_test_exon13],
              [:screening_failed?, :process_screening_failed_records],
              [:brca_diagnostic_test?, :process_brca_diagnostic_tests],
              [:class_3_unaffected_records?, :process_class_3_unaffected_records],
              [:pred_class4_positive_records?, :process_pred_class4_positive_records],
              [:brca_diag_tests?, :brca_double_negative],
              [:predictive_b2_pathological_neg_test?, :process_predictive_b2_pathological_neg_record],
              [:ngs_failed_mlpa_normal_test?, :brca_double_negative],
              [:ngs_screening_failed_tests?, :process_ngs_screening_failed_record],
              [:ngs_b1_and_b2_normal_mlpa_fail?, :brca_double_negative],
              [:brca_palb2_diag_normal_test?, :process_brca_palb2_diag_normal_record],
              [:ngs_brca2_multiple_exon_mlpa_positive?, :process_ngs_brca2_multiple_exon_mlpa_positive],
              [:brca2_class3_unknown_variant_test?, :process_brca2_class3_unknown_variant_records],
              [:mlpa_only_fail_test?, :process_mlpa_only_fail_record],
              [:brca_palb2_diagnostic_class3_test?, :process_brca_palb2_diagnostic_class3_record],
              [:generic_normal_test?, :process_generic_normal_record],
              [:brca_palb2_diag_class4_5_tests?, :process_brca_palb2_diag_class4_5_record],
              [:brca_diagnostic_class4_5_test?, :process_brca_diagnostic_class4_5_record],
              [:brca_palb2_mlpa_class4_5_tests?, :process_brca_palb2_mlpa_class4_5_record],
              [:brca_diag_class4_5_mlpa_tests?, :process_brca_diag_class4_5_mlpa_record],
              [:brca_diagnostic_class3?, :process_brca_diagnostic_class3_record],
              [:brca_palb2_diag_screening_failed_test?, :process_brca_palb2_diag_screening_failed_record]
            ]
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
            # insert loop here
            @genotype_condition_extraction_methods.each do |condition_extraction|
              condition, extraction = *condition_extraction
              if send(condition)
                send(extraction)
              end
            end
            @genotypes
          end
        end
      end
    end
  end
end
