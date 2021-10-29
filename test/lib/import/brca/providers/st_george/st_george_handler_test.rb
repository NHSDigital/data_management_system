require 'test_helper'

class StGeorgeHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::StGeorge::StGeorgeHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_moltesttype' do
    predictive_record = build_raw_record('pseudo_id1' => 'bob')
    predictive_record.raw_fields['moleculartestingtype'] = 'unaffected'
    @handler.add_moleculartestingtype(@genotype, predictive_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
    predictive_record = build_raw_record('pseudo_id1' => 'bob')
    predictive_record.raw_fields['moleculartestingtype'] = 'predictive'
    @handler.add_moleculartestingtype(@genotype, predictive_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record.raw_fields['moleculartestingtype'] = 'affected'
    @handler.add_moleculartestingtype(@genotype, diagnostic_record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
    diagnostic_record = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record.raw_fields['moleculartestingtype'] = 'confirmatory'
    @handler.add_moleculartestingtype(@genotype, diagnostic_record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  test 'process_genetictestscope' do
    void_record = build_raw_record('pseudo_id1' => 'bob')
    void_record.raw_fields['moleculartestingtype'] = ''
    assert_equal true, @handler.void_genetictestscope?(void_record)
    @logger.expects(:debug).with('Unknown moleculartestingtype')
    @handler.process_genetictestcope(@genotype, void_record)
    assert_nil(@genotype.attribute_map['genetictestscope'])

    ashkenazi_record = build_raw_record('pseudo_id1' => 'bob')
    ashkenazi_record.raw_fields['moleculartestingtype'] = 'Ashkenazi'
    assert_equal true, @handler.ashkenazi?(ashkenazi_record)
    @handler.process_genetictestcope(@genotype, ashkenazi_record)
    assert_equal 'AJ BRCA screen', @genotype.attribute_map['genetictestscope']

    polish_record = build_raw_record('pseudo_id1' => 'bob')
    polish_record.raw_fields['moleculartestingtype'] = 'Polish'
    assert_equal true, @handler.polish?(polish_record)
    @handler.process_genetictestcope(@genotype, polish_record)
    assert_equal 'Polish BRCA screen', @genotype.attribute_map['genetictestscope']

    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['moleculartestingtype'] = 'wjlrgq c.666A>G'
    assert_equal true, @handler.targeted_test?(targeted_record)
    @handler.process_genetictestcope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['moleculartestingtype'] = '?6174delT'
    assert_equal true, @handler.targeted_test?(targeted_record)
    @handler.process_genetictestcope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['moleculartestingtype'] = 'pred'
    assert_equal true, @handler.targeted_test?(targeted_record)
    @handler.process_genetictestcope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    full_screen_record = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record.raw_fields['moleculartestingtype'] = 'Full Screen'
    assert_equal true, @handler.full_screen?(full_screen_record)
    @handler.process_genetictestcope(@genotype, full_screen_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    full_screen_record = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record.raw_fields['moleculartestingtype'] =
      'BRCA1 & 2 exon deletion & duplication analysis'
    assert_equal true, @handler.full_screen?(full_screen_record)
    @handler.process_genetictestcope(@genotype, full_screen_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'process_single_record' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 6275_6276delTT')
    @logger.expects(:debug).with('FAILED protein parse for: BR2 c.6275_6276delTT')
    @handler.process_variants_from_record(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal 'c.6275_6276del', @genotype.attribute_map['codingdnasequencechange']
    fullscreen_record = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_record.raw_fields['moleculartestingtype'] = 'Full Screen'
    assert_equal true, @handler.full_screen?(fullscreen_record)
    # Test for full screen record
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 6275_6276delTT')
    @logger.expects(:debug).with('FAILED protein parse for: BR2 c.6275_6276delTT')
    variants = @handler.process_variants_from_record(@genotype, fullscreen_record)
    assert_equal 2, variants.size
    assert_equal 1, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genotype'] = 'Cabbage'
    @logger.expects(:debug).with('Unable to extract gene')
    variants = @handler.process_variants_from_record(@genotype, broken_record)
    assert true, variants.empty?
  end

  test 'process_multiple_cdnavariants' do
    multiple_cdnavariants_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdnavariants_record.raw_fields['genotype'] = 'BRCA1 c.666A>G + BR2 c.6275_6276del'
    variants = @handler.process_variants_from_record(@genotype, multiple_cdnavariants_record)
    assert_equal 2, variants.size
    assert_equal 2, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 8, variants[1].attribute_map['gene']
    assert_equal 'c.666A>G', variants[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.6275_6276del', variants[1].attribute_map['codingdnasequencechange']
  end

  test 'process_multiple_cdnavariants_protein_for_same_gene' do
    multiple_cdnavariants_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdnavariants_record.raw_fields['genotype'] = 'BR1 c.3005delA, c.3119G>A (p.Ser1040Asn)'
    variants = @handler.process_variants_from_record(@genotype, multiple_cdnavariants_record)
    assert_equal 2, variants.size
    assert_equal 2, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 7, variants[1].attribute_map['gene']
    assert_equal 'c.3005del', variants[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.3119G>A', variants[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Ser1040Asn', variants[1].attribute_map['proteinimpact']
  end

  test 'process_multiple_cdnavariants_for_same_gene' do
    multiple_cdnavariants_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdnavariants_record.raw_fields['genotype'] = 'BR1 c.3052ins5 (c.3048dupTGAGA)'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    variants = @handler.process_variants_from_record(@genotype, multiple_cdnavariants_record)
    assert_equal 2, variants.size
    assert_equal 2, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 7, variants[1].attribute_map['gene']
    assert_equal 'c.3052ins5', variants[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.3048dupTGAGA', variants[1].attribute_map['codingdnasequencechange']
  end

  test 'process_multiple_cdnavariants_multiple_delimiter' do
    multiple_cdnavariants_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdnavariants_record.raw_fields['genotype'] = 'BR1 +BR2 c.68_69delAG + c.5946delT'
    variants = @handler.process_variants_from_record(@genotype, multiple_cdnavariants_record)
    assert_equal 2, variants.size
    assert_equal 2, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 8, variants[1].attribute_map['gene']
    assert_equal 'c.68_69del', variants[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.5946del', variants[1].attribute_map['codingdnasequencechange']
  end

  test 'process_multiple_cdnavariants_square_brackets' do
    multiple_cdnavariants_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdnavariants_record.raw_fields['genotype'] = 'BRCA1: [c.3750delG]; BRCA2: [c.4447delA]'
    variants = @handler.process_variants_from_record(@genotype, multiple_cdnavariants_record)
    assert_equal 2, variants.size
    assert_equal 2, variants[0].attribute_map['teststatus']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 8, variants[1].attribute_map['gene']
    assert_equal 'c.3750del]', variants[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.4447del]', variants[1].attribute_map['codingdnasequencechange']
  end

  test 'process_single_exonvariant' do
    single_exon_variant_record = build_raw_record('pseudo_id1' => 'bob')
    single_exon_variant_record.raw_fields['genotype'] = 'Dup 13 BR1'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL exon variant parse for: Dup 13 BR1')
    @logger.expects(:debug).with('FAILED protein parse for: Dup 13 BR1')
    @handler.process_variants_from_record(@genotype, single_exon_variant_record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal '13', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 7, @genotype.attribute_map['gene']
    fullscreen_exon_variant_record = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_exon_variant_record.raw_fields['moleculartestingtype'] = 'Full Screen'
    fullscreen_exon_variant_record.raw_fields['genotype'] = 'Dup 13 BR1'
    assert_equal true, @handler.full_screen?(fullscreen_exon_variant_record)
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL exon variant parse for: Dup 13 BR1')
    @logger.expects(:debug).with('FAILED protein parse for: Dup 13 BR1')
    variants = @handler.process_variants_from_record(@genotype, fullscreen_exon_variant_record)
    assert_equal 1, variants[0].attribute_map['teststatus']
    assert_equal 8, variants[0].attribute_map['gene']
    assert_equal 2, variants[1].attribute_map['teststatus']
    assert_equal 7, variants[1].attribute_map['gene']
  end

  test 'process_failed_record' do
    failed_record_nogene = build_raw_record('pseudo_id1' => 'bob')
    failed_record_nogene.raw_fields['genotype'] = 'Failed'
    @logger.expects(:debug).with('Unable to extract gene')
    @logger.expects(:debug).with('FAILED gene parse for: Failed')
    @handler.process_variants_from_record(@genotype, failed_record_nogene)
    assert_equal 9, @genotype.attribute_map['teststatus']
    failed_record_gene = build_raw_record('pseudo_id1' => 'bob')
    failed_record_gene.raw_fields['genotype'] = 'Failed BR1'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @handler.process_variants_from_record(@genotype, failed_record_gene)
    assert_equal 9, @genotype.attribute_map['teststatus']
    assert_equal 7, @genotype.attribute_map['gene']
    fullscreen_failed_record = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_failed_record.raw_fields['genotype'] = 'Failed'
    fullscreen_failed_record.raw_fields['moleculartestingtype'] = 'Full Screen'
    @logger.expects(:debug).with('Unable to extract gene')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    variants = @handler.process_variants_from_record(@genotype, fullscreen_failed_record)
    assert_equal 2, variants.size
    assert_equal 9, variants[0].attribute_map['teststatus']
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 9, variants[1].attribute_map['teststatus']
    assert_equal 8, variants[1].attribute_map['gene']
  end

  test 'process_normal_record' do
    no_gene_normal_genotype_record = build_raw_record('pseudo_id1' => 'bob')
    no_gene_normal_genotype_record.raw_fields['genotype'] = 'Normal'
    assert_equal true, @handler.normal?(no_gene_normal_genotype_record)
    @logger.expects(:debug).with('Unable to extract gene')
    @logger.expects(:debug).with('FAILED gene parse for: Normal')
    @handler.process_variants_from_record(@genotype, no_gene_normal_genotype_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
    assert_nil(@genotype.attribute_map['gene'])
    normal_genotype_record_with_gene = build_raw_record('pseudo_id1' => 'bob')
    normal_genotype_record_with_gene.raw_fields['genotype'] = 'N'
    normal_genotype_record_with_gene.raw_fields['moleculartestingtype'] = 'BRCA1 predictive test'
    @logger.expects(:debug).with('Unable to extract gene')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: BRCA1')
    @handler.process_variants_from_record(@genotype, normal_genotype_record_with_gene)
    assert_equal true, @handler.normal?(no_gene_normal_genotype_record)
    assert_equal 7, @genotype.attribute_map['gene']
    assert_equal 1, @genotype.attribute_map['teststatus']
    normal_mtype_record_with_gene = build_raw_record('pseudo_id1' => 'bob')
    normal_mtype_record_with_gene.raw_fields['genotype'] = 'BR1 c.68_69delAG'
    normal_mtype_record_with_gene.raw_fields['moleculartestingtype'] = 'Predictive - unaffected'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @handler.process_variants_from_record(@genotype, normal_mtype_record_with_gene)
    assert_equal true, @handler.normal?(no_gene_normal_genotype_record)
    assert_equal 7, @genotype.attribute_map['gene']
    assert_equal 1, @genotype.attribute_map['teststatus']
    fs_normal_mtype_record_with_gene = build_raw_record('pseudo_id1' => 'bob')
    fs_normal_mtype_record_with_gene.raw_fields['genotype'] = 'N'
    fs_normal_mtype_record_with_gene.raw_fields['moleculartestingtype'] = 'Full Screen - unaffected'
    @logger.expects(:debug).with('Unable to extract gene')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    variants = @handler.process_variants_from_record(@genotype, fs_normal_mtype_record_with_gene)
    assert_equal true, @handler.normal?(fs_normal_mtype_record_with_gene)
    assert_equal true, @handler.full_screen?(fs_normal_mtype_record_with_gene)
    assert_equal 2, variants.size
    assert_equal 7, variants[0].attribute_map['gene']
    assert_equal 1, @genotype.attribute_map['teststatus']
    assert_equal 8, variants[1].attribute_map['gene']
    assert_equal 1, @genotype.attribute_map['teststatus']
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
      hospitalnumber: '332061',
      receiveddate: '1998-08-13T00:00:00.000+01:00',
      servicereportidentifier: 'D11585',
      specimentype: '5',
      age: 42 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      'g number' => '4241',
      genotype: 'BR2 c.6275_6276delTT',
      providercode: 'RMHS',
      referralorganisation: 'Royal Marsden Hospital',
      consultantname: 'Eeles',
      servicereportidentifier: 'D11585',
      servicelevel: 'NHS',
      collecteddate: '',
      receiveddate: '1998-08-13 00:00:00',
      authoriseddate: '',
      moleculartestingtype: '',
      specimentype: 'Blood' }.to_json
  end
end
