require 'test_helper'

class LeedsHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @logger = Import::Log.get_logger
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
    # @variant_processor = Import::Brca::Providers::Leeds::VariantProcessor.new(@genotype,
    #                                                                          @record, @logger)
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

  #
  #
  # test 'process_predictive_tests' do
  #   report_string = Maybe([@record.raw_fields['report'],
  #                   @record.mapped_fields['report'],
  #                   @record.raw_fields['firstofreport']].
  #                    reject(&:nil?).first).or_else('') # la report_string
  #   geno = Maybe(@record.raw_fields['genotype']).
  #          or_else(Maybe(@record.raw_fields['report_result']).
  #          or_else(''))
  #   report_string = 'Sequence analysis indicates that this patient is heterozygous for the '\
  #                   'pathogenic BRCA2 mutation c.3158T>G.\n\nThis result significantly increases '\
  #                   'her risk of developing BRCA2-associated cancers. \n\nThis result may have '\
  #                   'important implications for relatives, a'
  #                   genotype_string = 'predictive brca1 ngs pos'
  #
  #   genotypes = []
  #   @logger.expects(:debug).with('Sucessfully parsed positive pred record')
  #
  #   @handler.add_cdna_change_from_report(@genotype, @record)
  #   broken_record = build_raw_record('pseudo_id1' => 'bob')
  #   broken_record.mapped_fields['report'] = 'E;OUHF;A`HFD ;UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA'
  #   @logger.expects(:debug).with('FAILED cdna change parse for: E;OUHF;A`HFD ;'\
  #                                'UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA')
  #   @handler.add_cdna_change_from_report(@genotype, broken_record)
  # end
  #
  # test 'add_gene_cdna_protein_from_report' do
  #   @logger.expects(:debug).with('SUCCESSFUL gene parse for  BRCA1')
  #   @logger.expects(:debug).with('SUCCESSFUL cdna change parse for:  BRCA1, 5198A>G,')
  #   @handler.add_gene_cdna_protein_from_report(@genotype, @record)
  #   broken_record = build_raw_record('pseudo_id1' => 'bob')
  #   broken_record.mapped_fields['report'] = 'E;OUHF;A`HFD ;UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA'
  #   @logger.expects(:debug).with('FAILED gene,cdna,protein impact parse from report')
  #   @handler.add_gene_cdna_protein_from_report(@genotype, broken_record)
  # end
  #
  # test 'double_positives' do
  #   report_string = Maybe([@record.raw_fields['report'],
  #                   @record.mapped_fields['report'],
  #                   @record.raw_fields['firstofreport']].
  #                    reject(&:nil?).first).or_else('') # la report_string
  #   geno = Maybe(@record.raw_fields['genotype']).
  #          or_else(Maybe(@record.raw_fields['report_result']).
  #          or_else(''))
  #   @extractor.process(geno, report, @genotype)
  #   assert_equal 1, @extractor.process(geno, report, @genotype).size
  #   normal_record = build_raw_record_normal('pseudo_id1' => 'bob')
  #   normal_genotype = Import::Brca::Core::GenotypeBrca.new(normal_record)
  #   normal_report = Maybe([normal_record.raw_fields['report'],
  #                          normal_record.mapped_fields['report'],
  #                          normal_record.raw_fields['firstofreport']].
  #                   reject(&:nil?).first).or_else('') # la report_string
  #   normal_geno = Maybe(normal_record.raw_fields['genotype']).
  #                 or_else(Maybe(normal_record.raw_fields['report_result']).
  #                 or_else(''))
  #   @extractor.process(normal_geno, normal_report, normal_genotype)
  #   assert_equal 2, @extractor.process(normal_geno, normal_report, normal_genotype).size
  # end

  private

  # def build_raw_record_normal(options = {})
  #   default_options = {
  #     'pseudo_id1' => '',
  #     'pseudo_id2' => '',
  #     'encrypted_demog' => '',
  #     'clinical.to_json' => clinical_json_normal,
  #     'encrypted_rawtext_demog' => '',
  #     'rawtext_clinical.to_json' => rawtext_clinical_json_normal
  #   }
  #
  #   Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  # end

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

  # def clinical_json_normal
  #   { sex: '2',
  #     consultantcode: 'Consultant Code',
  #     providercode: 'Provider Code',
  #     receiveddate: '2019-10-25T00:00:00.000+01:00',
  #     authoriseddate: '2019-11-25T00:00:00.000+00:00',
  #     servicereportidentifier: 'Service Report Identifier',
  #     sortdate: '2019-10-25T00:00:00.000+01:00',
  #     genetictestscope: 'R208.1',
  #     specimentype: '5',
  #     report: 'This patient has been screened for BRCA1 and BRCA2 '\
  #             'mutations by sequence analysis and MLPA. No pathogenic mutation was identified.',
  #     requesteddate: '2019-10-25T00:00:00.000+01:00',
  #     age: 999 }.to_json
  # end
  #
  # def rawtext_clinical_json_normal
  #   { sex: 'F',
  #     'reffac.name' => 'Hospital Name',
  #     provider_address: 'Provider Address',
  #     providercode: 'Provider Code',
  #     referringclinicianname: 'Consultant Name',
  #     consultantcode: 'Consultant Code',
  #     servicereportidentifier: 'Service Report Identifier',
  #     patienttype: 'NHS',
  #     moleculartestingtype: 'R208.1',
  #     indicationcategory: 'R208',
  #     genotype: 'Normal B1/B2 - UNAFFECTED',
  #     report: 'This patient has been screened for BRCA1 and BRCA2 '\
  #             'mutations by sequence analysis and MLPA. No pathogenic mutation was identified.',
  #     receiveddate: '2019-10-25 00:00:00',
  #     requesteddate: ' 2019-10-25 00:00:00',
  #     authoriseddate: '2019-11-25 00:00:00',
  #     specimentype: 'Blood' }.to_json
  # end
end
