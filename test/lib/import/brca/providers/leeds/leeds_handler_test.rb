require 'test_helper'

class LeedsHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @logger = Import::Log.get_logger
    @logger.level = Logger::INFO
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Leeds::LeedsHandler.new(EBatch.new)
      @variant_processor = Import::Brca::Providers::Leeds::VariantProcessor.new(@genotype,
                                                                               @record, @logger)
    end
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'full_screen_test' do
    @variant_processor.genetictestscope_field = 'r208.1'
    assert_equal 'Full screen BRCA1 and BRCA2', @variant_processor.assess_scope_from_genotype
  end

  test 'targeted?' do
    @variant_processor.genetictestscope_field = 'confirmation'
    assert_equal 'Targeted BRCA mutation test', @variant_processor.assess_scope_from_genotype
  end

  test 'process_positive_predictive_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                       'heterozygous for the pathogenic BRCA2 mutation c.3158T>G. '\
                                       'This result significantly increases her risk of'\
                                       ' developing BRCA2-associated cancer. This result may have '\
                                       'important implications for relatives, a'
    @variant_processor.genotype_string = 'Predictive BRCA2 seq pos'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene'] 
    assert_equal 'c.3158T>G', res[0].attribute_map['codingdnasequencechange']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 5, res[0].attribute_map['variantpathclass']
  end

  test 'process_negative_predictive_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that the familial pathogenic '\
                                       'BRCA2 mutation c.8297del is absent in this patient.\n\n'\
                                       'This result significantly reduces her risk of developing '\
                                       'BRCA2-associated cancers. This result does not affect her '\
                                       'risk of developing other famil'
    @variant_processor.genotype_string = 'Predictive BRCA2 seq neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene'] 
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_negative_inherited_predictive_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient has not inherited '\
                                        'the familial BRCA1 mutation c.3319G>T (p.Glu1107X). This '\
                                        'result reduces her risk of developing breast/ovarian '\
                                        'cancer to that of the general population assuming no '\
                                        'other significant family history.'
    @variant_processor.genotype_string = 'Predictive BRCA1 seq neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene'] 
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_positive_inherited_predictive_test' do
    @variant_processor.report_string  = 'This patient is heterozygous for the familial pathogenic '\
                                        'BRCA1 deletion of exon 24.\n\nAs this patient is male, '\
                                        'his risk of developing BRCA1-related cancers remains low. '\
                                        'However, female relatives who inherit this mutation will '\
                                        'be at high risk of developing'
    @variant_processor.genotype_string = 'Predictive BRCA1 MLPA pos'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal '24', res[0].attribute_map['exonintroncodonnumber']
  end

  test 'process_negative_mlpa_test' do
    @variant_processor.report_string  = 'MLPA analysis indicates that the familial pathogenic BRCA1 '\
                                       'duplication of exon 13 is absent in this patient. \n\n'\
                                       'This reduces their risk of developing BRCA1-associated '\
                                       'cancers but does not affect their risk of developing '\
                                       'other familial or sporadic cancers.'
    @variant_processor.genotype_string = 'Predictive BRCA1 MLPA neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_positive_mlpa_test' do
    @variant_processor.report_string  = 'MLPA analysis indicates that this patient is heterozygous '\
                                        'for the pathogenic BRCA1 deletion that includes the '\
                                        'promoter - exon 3 interval. \n\nThis result '\
                                        'significantly increases this patient risk of developing '\
                                        'BRCA1-associated cancers.\n\nThis result may ha'
    @variant_processor.genotype_string = 'Predictive BRCA1 MLPA neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
  end

  test 'process_double_normal_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA. No pathogenic '\
                                        'mutation was identified. \n\nBased on family history, '\
                                        'this result does not exclude this patient cancer risk. '\
                                        'In addition, the possibility that a path'
    @variant_processor.genotype_string = 'Normal B1/B2 - UNAFFECTED'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_variant_sequence_test_single_variant' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the BRCA1 sequence variant c.1065G>A (p.Lys355Lys). This '\
                                        'change has previously been reported on the BIC database '\
                                        'as a variant of no clinical significance. In silico '\
                                        'analyses also suggest that it i'
    @variant_processor.genotype_string = 'B1 seq variant'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.1065G>A', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Lys355Lys', res[1].attribute_map['proteinimpact']
  end


  test 'process_variant_sequence_test_multiple_variants_same_gene' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the sequence variants c.68-7T>A in BRCA2 intron 2 and '\
                                        'c.6698C>A (Ala2233Asp) in BRCA2 exon 11. These variants '\
                                        'are both listed in the BIC database as being of unknown '\
                                        'clinical significance, and analy'
    @variant_processor.genotype_string = 'NGS B2 seq variant - class 3'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.68-7T>A', res[1].attribute_map['codingdnasequencechange']

    assert_equal 8, res[2].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 'c.6698C>A', res[2].attribute_map['codingdnasequencechange']
  end

  test 'process_variant_sequence_test_multiple_variants_multiple_genes' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the sequence variants c.736T>G (p.Leu246Val) in BRCA1 '\
                                        'and c.4068G>A (p.Leu1356Leu) in BRCA2. \nThese variants '\
                                        'have previously been reported on the BIC database as '\
                                        'unknown variants. In silico analyses'
    @variant_processor.genotype_string = 'NGS B1 and B2 seq variant'
    @variant_processor.genetictestscope_field = 'Mutation Screening'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.736T>G', res[0].attribute_map['codingdnasequencechange']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.4068G>A', res[1].attribute_map['codingdnasequencechange']
    end

  test 'process_variant_class_exonic_mutation_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                         'mutations by sequence analysis and MLPA.\n\nThis patient '\
                                         'is heterozygous for a pathogenic BRCA1 deletion '\
                                         'involving exon 3. This result is consistent with the '\
                                         'patient affected status, and the patient is at'
    @variant_processor.genotype_string = 'B1 Class 5 UV - MLPA'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal '3', res[1].attribute_map['exonintroncodonnumber']
    assert_equal 5, res[1].attribute_map['variantpathclass']
  end

  test 'process_variant_class_promoter_exonic_mutation_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA.\n\nThis patient '\
                                        'is heterozygous for a pathogenic BRCA1 deletion '\
                                        'involving exon 3. This result is consistent with the '\
                                        'patient affected status, and the patient is at'
    @variant_processor.genotype_string = 'B1 Class 5 UV - MLPA'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal '3', res[1].attribute_map['exonintroncodonnumber']
    assert_equal 5, res[1].attribute_map['variantpathclass']
  end

  test 'process_variant_class_promoter_exonic_mutation_exceptions_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA. This patient is '\
                                        'heterozygous for the pathogenic BRCA1 mutation c.66dup '\
                                        'p.(Glu23fs), also detected as an apparent exon 2 deletion '\
                                        'in MLPA analysis.\n\nThis result sig'
    @variant_processor.genotype_string = 'B1 Class 5 UV - unaffected patient'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal '2', res[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_variant_class_cdna_variant_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA. This patient is '\
                                        'heterozygous for the pathogenic BRCA1 mutation '\
                                        'c.2681_2682del p.(Lys894fs). This result is consistent '\
                                        'with the patient affected status, and the p'
    @variant_processor.genotype_string = 'B1 Class 5 UV'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 5, res[1].attribute_map['variantpathclass']
    assert_equal 'c.2681_2682del', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Lys894fs', res[1].attribute_map['proteinimpact']
  end

  test 'process_variant_class_cdna_variant_type_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA. This patient is '\
                                        'heterozygous for the pathogenic BRCA1 splice site '\
                                        'mutation c.80+2T>G. \n\nThis result is consistent with '\
                                        'the patient affected status, and the patie'
    @variant_processor.genotype_string = 'B1 Class 5 UV'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 5, res[1].attribute_map['variantpathclass']
    assert_equal 'c.80+2T>G', res[1].attribute_map['codingdnasequencechange']
  end

  test 'process_negative_confirmation_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient does not have the '\
                                        'familial pathogenic BRCA2 mutation c.1265del. \n\n'\
                                        'However, this analysis is unable to exclude the '\
                                        'possibility that there is a germline pathogenic mutation '\
                                        'in BRCA2, or another cancer susceptibility gene'
    @variant_processor.genotype_string = 'Confirmation B2 seq neg'
    @variant_processor.genetictestscope_field = 'Confirmation'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_positive_confirmation_predictive_cdna_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the familial pathogenic BRCA2 mutation c.6588_6589del.  '\
                                        '\n\nThis is consistent with the patient affected status '\
                                        'and the patient is at high risk of developing further '\
                                        'BRCA2-related cancers. \n\nThis re'
    @variant_processor.genotype_string = 'Confirmation B2 seq pos'
    @variant_processor.genetictestscope_field = 'Confirmation'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.6588_6589del', res[0].attribute_map['codingdnasequencechange']
  end

  test 'process_positive_confirmation_exonic_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the familial pathogenic BRCA1 deletion of exons 1-3.  '\
                                        '\n\nThis is consistent with the patient affected status '\
                                        'and the patient is at high risk of developing further '\
                                        'BRCA1-related cancers. \n\nThis resu'
    @variant_processor.genotype_string = 'Confirmation B2 seq pos'
    @variant_processor.genetictestscope_field = 'Confirmation'

    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal '1-3', res[0].attribute_map['exonintroncodonnumber']
  end
  
  test 'process_positive_confirmation_mlpa_exonic_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the pathogenic BRCA1 exon 13 '\
                                        'duplication.  This is consistent with the patient '\
                                        'affected status and the patient is at high risk of '\
                                        'developing further BRCA1-related cancers.'
    @variant_processor.genotype_string = 'Confirmation B1 seq pos'
    @variant_processor.genetictestscope_field = 'Confirmation'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal '13', res[0].attribute_map['exonintroncodonnumber']
  end

  test 'process_positive_confirmation_cdna_variant_class_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the familial likely pathogenic BRCA2 variant c.7988A>T.  '\
                                        'This is consistent with the patient affected status '\
                                        'and assuming c.7988A>T represents the pathogenic change '\
                                        'in this family, the patient is'
    @variant_processor.genotype_string = 'Confirmation B2 seq pos'
    @variant_processor.genetictestscope_field = 'Confirmation'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.7988A>T', res[0].attribute_map['codingdnasequencechange']
  end

  test 'process_positive_ashkenazi_positive_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the familial pathogenic BRCA1 mutation '\
                                        'c.68_69del. \n\nThis result increases her risk of '\
                                        'developing BRCA1-associated cancers. \n\nThis result may '\
                                        'have important implications for relatives, and'
    @variant_processor.genotype_string = 'Predictive AJ pos 3seq'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'AJ BRCA screen', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.68_69del', res[0].attribute_map['codingdnasequencechange']
  end

  test 'process_positive_ashkenazi_negative_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that the familial pathogenic '\
                                        'BRCA1 mutation c.68_69del is absent in this patient.\n'\
                                        'This result significantly reduces their risk of '\
                                        'developing BRCA1-associated cancers. This result does not '\
                                        'affect their risk of developing other f'
    @variant_processor.genotype_string = 'Predictive AJ neg 3seq'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'AJ BRCA screen', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end
  
  test 'process_double_normal_mlpa_failed_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis, and for BRCA1 mutations '\
                                        'by MLPA. No pathogenic mutation was identified.\n\n'\
                                        'Unfortunately, MLPA analysis of BRCA2 failed despite '\
                                        'repeated attempts. Should MLPA analysis still'
    @variant_processor.genotype_string = 'Normal B1 and B2, MLPA fail'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[2].attribute_map['gene']
    assert_equal 9, res[2].attribute_map['teststatus']
  end

  test 'process_truncating_mutation_cdna_type_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the frameshift mutation '\
                                        'c.4065_4068delTCAA (p.Asn1355fs) in BRCA1 '\
                                        '[see accompanying sheet for details]. This mutation has '\
                                        'previously been reported in the '\
                                        'literature (#) and on the BIC datab'
    @variant_processor.genotype_string = 'B1 truncating/frameshift'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.4065_4068del', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Asn1355fs', res[1].attribute_map['proteinimpact']

  end

  test 'process_truncating_possibly_multiple_mutations_test' do
    @variant_processor.report_string  = 'Additional mutations detected: ¹c.4189G>A het. '\
                                        '²c.5945G>C het.\nAdditional worksheet refs: PCR10/2844, '\
                                        'PCR10/2845, PCR10/2846, PCR10/2847, PCR10/2848, '\
                                        'PCR10/2849.\n\nSequence analysis indicates that this '\
                                        'patient is heterozygous for the frameshift deletion/in'
    @variant_processor.genotype_string = 'NGS B2 truncating/frameshift'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.4189G>A', res[1].attribute_map['codingdnasequencechange']
    assert_equal 8, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 'c.5945G>C', res[2].attribute_map['codingdnasequencechange']
  end

  test 'process_word_report_test_full_screen' do
    @variant_processor.report_string  = 'word report - normal'
    @variant_processor.genotype_string = 'word report - normal'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 4, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 4, res[1].attribute_map['teststatus']
  end

  test 'process_word_report_test_targeted' do
    @variant_processor.report_string  = 'word report - normal'
    @variant_processor.genotype_string = 'word report - normal'
    @variant_processor.genetictestscope_field = 'Prenatal'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
  end

  test 'process_class_m_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the pathogenic mutation '\
                                        'c.4478_4481delAAAG (p.Glu1493fs) in BRCA2 exon 11. This '\
                                        'result is consistent with the patient affected status, '\
                                        'and the patient is at high risk of developing furthe'
    @variant_processor.genotype_string = 'NGS B2 Class M'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.4478_4481del', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Glu1493fs', res[1].attribute_map['proteinimpact']
  end

  test 'process_familial_class_cdna_variant_class_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the BRCA2 sequence variant c.441A>G. '\
                                        '\n\nAs the clinical significance of this variant is '\
                                        'currently uncertain, we are unable to refine this patient '\
                                        'risk of developing BRCA2-associated cancer'
    @variant_processor.genotype_string = 'Familial Class 3 pos'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.441A>G', res[0].attribute_map['codingdnasequencechange']
    assert_equal 3, res[0].attribute_map['variantpathclass']
  end

  test 'process_familial_class_cdna_mutation_type_test' do
    @variant_processor.report_string  = 'Sanger sequence analysis detected the BRCA1 sequence '\
                                        'variant of uncertain clinical significance c.593+1G>A in '\
                                        'this patient tissue sample with a ratio to the normal '\
                                        'allele comparable to the germline heterozygous pattern. '\
                                        'Please note that while there is no evidence to support '\
                                        'loss of heterozygosity, quantification of allelic balance '\
                                        'is outside the scope of this assay.'
    @variant_processor.genotype_string = 'Familial Class 3 pos'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.593+1G>A', res[0].attribute_map['codingdnasequencechange']
    assert_equal 3, res[0].attribute_map['variantpathclass']
  end

  test 'process_familial_class_negative_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that the BRCA2 sequence '\
                                        'variant c.441A>G is absent in this patient.\n\nAs the '\
                                        'clinical significance of this variant is currently '\
                                        'uncertain, we are unable to refine this patient risk of '\
                                        'developing BRCA2-associated cancer.'
    @variant_processor.genotype_string = 'Familial Class 3 neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_class4_predictive_negative_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that the likely pathogenic '\
                                        'BRCA2 sequence variant c.520C>T is absent in this patient. '\
                                        '\n\nThis result significantly reduces their risk of '\
                                        'developing BRCA2-associated cancers. This result does not '\
                                        'affect their risk of developing o'
    @variant_processor.genotype_string = 'Pred Class 4 seq negative'
    @variant_processor.genetictestscope_field = 'Predictive'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_process_brca2_pttshift_records_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the nonsense mutation c.5682C>G (p.Tyr1894X). This '\
                                        'mutation was originally detected by PTT and confirmed by '\
                                        'sequence analysis. This is likely to represent the '\
                                        'pathogenic mutation in this patient.'
    @variant_processor.genotype_string = 'B2 PTT shift'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.5682C>G', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Tyr1894x', res[1].attribute_map['proteinimpact']
  end

  test 'process_b1_mlpa_exon_positive_records_test' do
    @variant_processor.report_string  = 'MLPA analysis indicates that this patient is heterozygous '\
                                        'for a deletion including exons 1-23 of the BRCA1 gene. '\
                                        'According to the literature* it is highly likely that '\
                                        'this mutation is pathogenic and is consistent with the '\
                                        'patient affected status.  Testi'
    @variant_processor.genotype_string = 'B1 (multiple exon) MLPA+ve'
    @variant_processor.genetictestscope_field = 'Mutation Screening'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal '1-23', res[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_mlpa_negative_screening_failed_test' do
    @variant_processor.report_string  = 'MLPA analysis of BRCA1 and BRCA2 showed no evidence of a '\
                                        'deletion or duplication within either gene. \n\n'\
                                        'Screening for mutations in BRCA1 and BRCA2 is '\
                                        'now complete.'
    @variant_processor.genotype_string = 'screening failed; MLPA normal'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    # res = @variant_processor.process_positive_predictive
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end


  test 'process_brca_diagnostic_normal_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. No pathogenic '\
                                        'variant was identified.'
    @variant_processor.genotype_string = 'BRCA - Diagnostic Normal'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_positive_predictive_test_exon13_duplication_test' do
    @variant_processor.report_string  = 'PCR analysis using duplication-specific primers for the '\
                                        'BRCA1 exon 13 duplication indicates that this patient has '\
                                        'inherited the familial BRCA1 exon 13 duplication. This '\
                                        'result significantly increases her risk of developing '\
                                        'breast/ovarian cancer. \n\nThis re'
    @variant_processor.genotype_string = 'Predictive Ex13 dup pos'
    @variant_processor.genetictestscope_field = 'Predictive'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal '13', res[0].attribute_map['exonintroncodonnumber']
  end

  test 'process_negative_predictive_test_exon13_duplication_test' do
    @variant_processor.report_string  = 'PCR analysis indicates that the familial pathogenic '\
                                        'BRCA1 exon 13 duplication is absent in this patient. '\
                                        'This result significantly reduces her risk of developing '\
                                        'BRCA1-associated cancers. \n\nThis result does not affect '\
                                        'her risk of developing other familial'
    @variant_processor.genotype_string = 'Predictive Ex13 dup neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_failed_screening_test' do
    @variant_processor.report_string  = 'No results were obtained from this sample despite '\
                                        'repeated attempts.\nA repeat sample (20ml of blood in '\
                                        'EDTA or DNA) is therefore requested.'
    @variant_processor.genotype_string = 'screening failed'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
  end

  test 'process_brca_positive_diagnostic_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. This patient is '\
                                        'heterozygous for the pathogenic BRCA2 variant '\
                                        'c.6275_6276del p.(Leu2092fs). This result is consistent '\
                                        'with the patient affected status, and the patient is at '\
                                        'high risk of developing further BRCA2-related cancers. '\
                                        'This result may have important implications for other '\
                                        'family members and testing is available if appropriate. '\
                                        'We recommend that those relatives are referred to their '\
                                        'local Clinical Genetics department.'
    @variant_processor.genotype_string = 'BRCA - Diagnostic Class 5'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.6275_6276del', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Leu2092fs', res[1].attribute_map['proteinimpact']
  end

  test 'process_brca_negative_diagnostic_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                         'BRCA2 by sequence and dosage analysis. No pathogenic '\
                                         'variant was identified. Based on family history, this '\
                                         'result does not exclude this patient cancer risk. In '\
                                         'addition, the possibility that a pathogenic variant in '\
                                         'BRCA1, BRCA2, or another cancer susceptibility gene '\
                                         'segregates in this patient family cannot be excluded. '\
                                         'Screening of relatives is available on '\
                                         'request as appropriate.'
    @variant_processor.genotype_string = 'BRCA - Diagnostic Normal - UNAFFECTED'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_class_3_positive_unaffected_test' do
    @variant_processor.report_string  = 'This patient has been screened for BRCA1 and BRCA2 '\
                                        'mutations by sequence analysis and MLPA. \n\nThis patient '\
                                        'is heterozygous for the BRCA1 sequence variant c.591C>T. '\
                                        'This variant has been reported in patient cohorts while '\
                                        'being very rare in population contr'
    @variant_processor.genotype_string = 'Class 3 - UNAFFECTED'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.591C>T', res[1].attribute_map['codingdnasequencechange']
    assert_equal 3, res[1].attribute_map['variantpathclass']
  end
  
  test 'process_predictive_class4_positive_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that this patient is '\
                                        'heterozygous for the likely pathogenic BRCA1 sequence '\
                                        'variant c.181T>C. \n\nThis result increases this patient '\
                                        'risk of developing BRCA1-associated cancers.\nThis result '\
                                        'may have important implications for re'
    @variant_processor.genotype_string = 'Pred Class 4 seq positive'
    @variant_processor.genetictestscope_field = 'Predictive'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.181T>C', res[0].attribute_map['codingdnasequencechange']
    assert_equal 4, res[0].attribute_map['variantpathclass']
  end

  test 'process_brca_diag_negative_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. No pathogenic '\
                                        'variant was identified.'
    @variant_processor.genotype_string = 'BRCA MS Diag Normal'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_negative_predictive_b2_pathological_test' do
    @variant_processor.report_string  = 'Sequence analysis indicates that the familial pathogenic '\
                                        'BRCA2 variant c.956dup is absent in this patient. This '\
                                        'result significantly reduces her risk of developing '\
                                        'BRCA2-associated cancers. This result does not affect '\
                                        'her risk of developing other familial or sporadic cancers.'
    @variant_processor.genotype_string = 'Pred B2 C4/C5 seq neg'
    @variant_processor.genetictestscope_field = 'Predictive'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'ngs_failed_mlpa_normal_test' do
    @variant_processor.report_string  = 'MLPA analysis of BRCA1 and BRCA2 showed no evidence of a '\
                                        'deletion or duplication within either gene. No '\
                                        'sequencing results were obtained from this sample despite '\
                                        'repeated attempts.\nA repeat sample (3-5ml of blood in '\
                                        'EDTA or DNA) is therefore requested.'
    @variant_processor.genotype_string = 'NGS failed; MLPA normal'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_ngs_screening_failed_test' do
    @variant_processor.report_string  = 'No results were obtained from this sample.\nA repeat '\
                                        'sample (3-5ml of blood in EDTA or DNA) is '\
                                        'therefore requested.'
    @variant_processor.genotype_string = 'NGS screening failed'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
  end

  test 'process_ngs_B1_and_B2_normal_mlpa_fail_test' do
    @variant_processor.report_string  = 'This patient has been screened for mutations in all '\
                                        'coding exons of BRCA1 and BRCA2 by sequence analysis '\
                                        '[see notes below]. No pathogenic mutation was identified. '\
                                        'MLPA analysis did not detect any deletions or '\
                                        'duplications in BRCA2.\n\nUnfortunately, MLPA a'
    @variant_processor.genotype_string = 'NGS B1 and B2 normal, MLPA fail'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_brca_palb2_diag_normal_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1, '\
                                        'BRCA2 and PALB2 by sequence and dosage analysis. No '\
                                        'pathogenic variant was identified. Based on family '\
                                        'history, this result does not exclude this patient cancer '\
                                        'risk. In addition, the possibility that a pathogenic '\
                                        'variant in BRCA1, BRCA2, PALB2 or another cancer '\
                                        'susceptibility gene segregates in this patient family '\
                                        'cannot be excluded. Screening of relatives is available '\
                                        'on request as appropriate.'
    @variant_processor.genotype_string = 'BRCA/PALB2 Diag Normal - UNAFF'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[2].attribute_map['genetictestscope']
    assert_equal 3186, res[2].attribute_map['gene']
    assert_equal 1, res[2].attribute_map['teststatus']
  end

  test 'process_ngs_positive_brca2_multiple_exon_mlpa_test' do
    @variant_processor.report_string  = 'MLPA analysis of BRCA2 indicates that this patient is '\
                                        'heterozygous for deletion including exons 14-16 of the '\
                                        'BRCA2 gene. This result is consistent with their affected '\
                                        'status.\nTesting for this mutation is now available to '\
                                        'this patient at risk relatives'
    @variant_processor.genotype_string = 'NGS B2(multiple exon)MLPA+ve'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal '14-16', res[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_brca2_class3_unknown_variant_test' do
    @variant_processor.report_string  = 'Analysis indicates that this patient is heterozygous for '\
                                        'the BRCA2 sequence variant c.6953G>A (p.Arg2318Gln). '\
                                        'Evaluation of the available evidence is inconclusive*, '\
                                        'therefore the pathogenicity of this variant '\
                                        'cannot be determined.'
    @variant_processor.genotype_string = 'B2 Class 3b UV'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'c.6953G>A', res[1].attribute_map['codingdnasequencechange']
    assert_equal 3, res[1].attribute_map['variantpathclass']
    assert_equal 'p.Arg2318Gln', res[1].attribute_map['proteinimpact']
  end

  test 'process_mlpa_only_fail_test' do
    @variant_processor.report_string  = 'Unfortunately, MLPA analysis of BRCA1 and BRCA2 failed '\
                                        'despite repeated attempts, due to poor sample quality. '\
                                        'Should MLPA analysis still be required, please send a '\
                                        'fresh sample (3-5ml blood in EDTA or DNA from an '\
                                        'independent extraction).'
    @variant_processor.genotype_string = 'MLPA only fail'
    @variant_processor.genetictestscope_field = 'Diagnostic'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
  end

  test 'process_brca_palb2_diagnostic_class3_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1, '\
                                        'BRCA2 and PALB2 by sequence and dosage analysis. This '\
                                        'patient is heterozygous for the BRCA1 variant c.5332+3A>G. '\
                                        'Evaluation of the available evidence regarding the '\
                                        'pathogenicity of this variant is inconclusive. This '\
                                        'variant has not previously been reported in the '\
                                        'literature in patient cohorts, and it is rare in '\
                                        'population control datasets.¹ In silico predictions '\
                                        'suggest that this variant is not likely to affect RNA '\
                                        'splicing,² but this prediction has not been confirmed by '\
                                        'transcriptional studies. Therefore, predictive testing '\
                                        'for this variant is not indicated for relatives. Based '\
                                        'on family history, and uncertainty surrounding this '\
                                        'variant, this result neither confirms nor excludes this '\
                                        'patient cancer risk. In addition, the possibility that a '\
                                        'pathogenic mutation in BRCA1, BRCA2, PALB2 or another '\
                                        'cancer susceptibility gene segregates in this patient '\
                                        'family cannot be excluded. Screening of relatives is '\
                                        'available on request as appropriate.'
    @variant_processor.genotype_string = 'BRCA/PALB2 - Diag C3 UNAFF'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 3186, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 7, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 'c.5332+3A>G', res[2].attribute_map['codingdnasequencechange']
    assert_equal 3, res[2].attribute_map['variantpathclass']
  end

  test 'process_generic_normal_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in the '\
                                        'following cancer predisposing genes by sequence and '\
                                        'dosage analysis: BRCA1, BRCA2, PALB2, TP53. No pathogenic '\
                                        'variant was identified.'
    @variant_processor.genotype_string = 'Generic normal'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 4, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 3186, res[2].attribute_map['gene']
    assert_equal 1, res[2].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 79, res[3].attribute_map['gene']
    assert_equal 1, res[3].attribute_map['teststatus']
  end

  test 'process_brca_palb2_diag_class4_5_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1, '\
                                        'BRCA2 and PALB2 by sequence and dosage analysis. This '\
                                        'patient is heterozygous for the pathogenic BRCA2 sequence '\
                                        'variant c.6588_6589del p.(Lys2196fs). This result is '\
                                        'consistent with the patient affected status, and the '\
                                        'patient is at high risk of developing further '\
                                        'BRCA2-related cancers. This result may have important '\
                                        'implications for other family members and testing is '\
                                        'available if appropriate. We recommend that those '\
                                        'relatives are referred to their local '\
                                        'Clinical Genetics department.'
    @variant_processor.genotype_string = 'BRCA/PALB2 - Diag C4/5'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 3186, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[2].attribute_map['genetictestscope']
    assert_equal 'c.6588_6589del', res[2].attribute_map['codingdnasequencechange']
    assert_equal 'p.Lys2196fs', res[2].attribute_map['proteinimpact']
    assert_equal 5, res[2].attribute_map['variantpathclass']
  end

  test 'process_brca_diagnostic_class4_5_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. This patient is '\
                                        'heterozygous for the pathogenic BRCA2 sequence variant '\
                                        'c.5909C>A p.(Ser1970Ter). This result is consistent with '\
                                        'the patient affected status, and the patient is at high '\
                                        'risk of developing further BRCA2-related cancers. This '\
                                        'result may have important implications for relatives, '\
                                        'and testing is now available as appropriate if these '\
                                        'individuals are referred by their local '\
                                        'Clinical Genetics department.'
    @variant_processor.genotype_string = 'BRCA MS - Diag C4/5'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 'c.5909C>A', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Ser1970Ter', res[1].attribute_map['proteinimpact']
    assert_equal 5, res[1].attribute_map['variantpathclass']
  end

  test 'process_brca_palb2_mlpa_class4_5_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1, '\
                                        'BRCA2 and PALB2 by sequence and dosage analysis. This '\
                                        'patient is heterozygous for the pathogenic BRCA1 '\
                                        'duplication of exon 13. This result is consistent with '\
                                        'the patient affected status, and the patient is at high '\
                                        'risk of developing further BRCA1-related cancers. This '\
                                        'result may have important implications for other family '\
                                        'members and testing is available if appropriate. We '\
                                        'recommend that those relatives are referred to their '\
                                        'local Clinical Genetics department.'
    @variant_processor.genotype_string = 'BRCA/PALB2 - Diag C4/5 MLPA'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 3186, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 7, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[2].attribute_map['genetictestscope']
    assert_equal '13', res[2].attribute_map['exonintroncodonnumber']
    assert_equal 5, res[2].attribute_map['variantpathclass']
  end
  
  test 'process_brca_diag_class4_5_mlpa_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. This patient is '\
                                        'heterozygous for a pathogenic BRCA1 deletion including '\
                                        'exons 5-7. This result is consistent with the patient '\
                                        'affected status, and the patient is at high risk of '\
                                        'developing further BRCA1-related cancers. This result may '\
                                        'have important implications for other family members and '\
                                        'testing is available if appropriate. We recommend that '\
                                        'this patient is referred to their local Clinical '\
                                        'Genetics department.'
    @variant_processor.genotype_string = 'BRCA MS Diag C4/C5 - MLPA'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal '5-7', res[1].attribute_map['exonintroncodonnumber']
    assert_equal 5, res[1].attribute_map['variantpathclass']
  end
  
  test 'process_brca_diagnostic_class3_test' do
    @variant_processor.report_string  = 'This patient has been screened for variants in BRCA1 and '\
                                        'BRCA2 by sequence and dosage analysis. This patient is '\
                                        'heterozygous for the BRCA1 sequence variant c.4654T>C '\
                                        'p.(Tyr1552His). In silico analysis suggests that this '\
                                        'variant is not pathogenic¹, however in the absence of '\
                                        'further evidence this variant is of uncertain clinical '\
                                        'significance. Therefore, predictive testing '\
                                        'is not indicated for relatives.'
    @variant_processor.genotype_string = 'BRCA MS - Diag C3'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.4654T>C', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Tyr1552His', res[1].attribute_map['proteinimpact']
    assert_equal 3, res[1].attribute_map['variantpathclass']
  end


  test 'process_brca_palb2_diag_screening_failed_test' do
    @variant_processor.report_string  = 'No results were obtained from this sample. A repeat '\
                                        'sample (3-5ml of blood in EDTA or DNA) '\
                                        'is therefore requested.'
    @variant_processor.genotype_string = 'BRCA/PALB2 Diag screening failed'
    @variant_processor.genetictestscope_field = 'R208.1'
    @variant_processor.assess_scope_from_genotype
    res = @variant_processor.process_tests
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
    assert_equal 'Full screen BRCA1 and BRCA2', res[2].attribute_map['genetictestscope']
    assert_equal 3186, res[2].attribute_map['gene']
    assert_equal 9, res[2].attribute_map['teststatus']
  end

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_clinical_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-10-25T00:00:00.000+01:00',
      authoriseddate: '2019-11-25T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2019-10-25T00:00:00.000+01:00',
      genetictestscope: 'R208.1',
      specimentype: '5',
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by '\
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the '\
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). '\
              'This variant involves a moderately-conserved protein position. '\
              'It is found in population control sets at low frequency, '\
              'and functional studies suggest that '\
              'the resultant protein is functional². Evaluation of the available evidence regarding the '\
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of '\
              'uncertain significance. Therefore, predictive testing is not indicated for relatives.',
      requesteddate: '2019-10-25T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      'reffac.name' => 'Hospital Name',
      provider_address: 'Provider Address',
      providercode: 'Provider Code',
      referringclinicianname: 'Consultant Name',
      consultantcode: 'Consultant Code',
      servicereportidentifier: 'Service Report Identifier',
      patienttype: 'NHS',
      moleculartestingtype: 'R208.1',
      indicationcategory: 'R208',
      genotype: 'BRCA MS - Diag C3',
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by '\
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the '\
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). '\
              'This variant involves a moderately-conserved protein position. '\
              'It is found in population control sets at low frequency, and functional studies suggest that '\
              'the resultant protein is functional². Evaluation of the available evidence regarding the '\
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of '\
              'uncertain significance. Therefore, predictive testing is not indicated for relatives.',
      receiveddate: '2019-10-25 00:00:00',
      requesteddate: '2019-10-25 00:00:00',
      authoriseddate: '2019-11-25 00:00:00',
      specimentype: 'Blood' }.to_json
  end


end
