require 'test_helper'

class LeedsHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Leeds::LeedsHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'add_positive_teststatus' do
    @handler.populate_variables(@record)
    assert_equal 2, @handler.find_test_status(@record)
  end

  test 'add_gene_from_report' do
    @handler.populate_variables(@record)
    @handler.add_scope(@genotype, @record)
    genotypes = @handler.process_variants_from_record(@genotype, @record)
    assert_equal 'c.847C>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg283x', genotypes[0].attribute_map['proteinimpact']
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['report'] = 'This patient has been screened for MLH1, MSH2, MSH6 and ' \
                                         'PMS2 mutations by sequence and dosage analysis. No pathogenic mutation was identified.' \
                                         '\n\n\n\nThis result does not exclude a diagnosis of Lynch syndrome.\n\nTesting for other ' \
                                         'genes involved in familial bowel cancer is available if appropriate.'
    @handler.populate_variables(normal_record)
    @handler.add_scope(@genotype, normal_record)
    assert_equal 4, @handler.process_variants_from_record(@genotype, normal_record).size
  end

  test 'process_scope' do
    @handler.populate_variables(@record)
    @handler.add_scope(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'add_molecular_testingtype' do
    @handler.populate_variables(@record)
    @handler.add_molecular_testingtype(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  test 'varclass and teststatus' do
    @handler.populate_variables(@record)
    @handler.add_scope(@genotype, @record)
    @handler.add_varclass
    genotypes = @handler.process_variants_from_record(@genotype, @record)
    assert_equal 5, genotypes[0].attribute_map['variantpathclass']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
  end

  test 'normal_variant_record' do
    normal_variant_record = build_raw_record('pseudo_id1' => 'bob')
    normal_variant_record.raw_fields['report'] = 'This patient is heterozygous for the sequence variant ' \
                                                 'c.1537A>G (p.Ile513Val) in exon 4 of APC'
    normal_variant_record.raw_fields['genotype'] = 'FAP UV Class2'
    @handler.populate_variables(normal_variant_record)
    @handler.add_varclass
    @handler.add_scope(@genotype, normal_variant_record)
    genotypes = @handler.process_variants_from_record(@genotype, normal_variant_record)
    assert_equal 1, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['variantpathclass']
    assert_equal 10, genotypes[0].attribute_map['teststatus']
    assert_equal 358, genotypes[0].attribute_map['gene']
    assert_equal 'c.1537A>G', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal '4', genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 'p.Ile513Val', genotypes[0].attribute_map['proteinimpact']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
  end

  test 'failed targeted record' do
    failed_targ_record = build_raw_record('pseudo_id1' => 'bob')
    failed_targ_record.raw_fields['moleculartestingtype'] = 'Carrier test'
    failed_targ_record.raw_fields['genotype'] = 'Analysis failed'
    failed_targ_record.raw_fields['report'] = 'No results were obtained from this sample despite repeated attempts'

    @handler.populate_variables(failed_targ_record)
    @handler.add_varclass
    @handler.add_scope(@genotype, failed_targ_record)
    genotypes = @handler.process_variants_from_record(@genotype, failed_targ_record)
    assert_equal 1, genotypes.size
    assert_nil genotypes[0].attribute_map['variantpathclass']
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 3394, genotypes[0].attribute_map['gene']
    assert_equal 'Targeted Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
  end

  test 'positive targeted record' do
    pos_targ_record = build_raw_record('pseudo_id1' => 'bob')
    pos_targ_record.raw_fields['moleculartestingtype'] = 'Predictive'
    pos_targ_record.raw_fields['genotype'] = 'Pred seq class 5 +ve'
    pos_targ_record.raw_fields['report'] = 'Sequence analysis indicates that this patient is heterozygous for the familial pathogenic MSH2 variant c.488T>G.'

    @handler.populate_variables(pos_targ_record)
    @handler.add_varclass
    @handler.add_scope(@genotype, pos_targ_record)
    genotypes = @handler.process_variants_from_record(@genotype, pos_targ_record)
    assert_equal 1, genotypes.size
    assert_equal 5, genotypes[0].attribute_map['variantpathclass']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 'c.488T>G', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'Targeted Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
  end

  test 'normal fullscreen record' do
    norm_fs_record = build_raw_record('pseudo_id1' => 'bob')
    norm_fs_record.raw_fields['moleculartestingtype'] = 'R210.2'
    norm_fs_record.raw_fields['genotype'] = 'Lynch Diag; normal'
    norm_fs_record.raw_fields['report'] = 'This patient has been screened for MLH1, MSH2, MSH6 and PMS2 variants by sequence and dosage analysis. ' \
                                          'No pathogenic variant was identified.'

    @handler.populate_variables(norm_fs_record)
    @handler.add_varclass
    @handler.add_scope(@genotype, norm_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, norm_fs_record)

    assert_equal 4, genotypes.size
    assert_nil genotypes[0].attribute_map['variantpathclass']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2744, genotypes[0].attribute_map['gene']

    assert_nil genotypes[1].attribute_map['variantpathclass']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[1].attribute_map['genetictestscope']
    assert_equal 2804, genotypes[1].attribute_map['gene']

    assert_nil genotypes[2].attribute_map['variantpathclass']
    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[2].attribute_map['genetictestscope']
    assert_equal 2808, genotypes[2].attribute_map['gene']

    assert_nil genotypes[3].attribute_map['variantpathclass']
    assert_equal 1, genotypes[3].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[3].attribute_map['genetictestscope']
    assert_equal 3394, genotypes[3].attribute_map['gene']
  end

  test 'abnormal fs multi var single gene record' do
    abnormal_fs_single_gene_rec = build_raw_record('pseudo_id1' => 'bob')
    abnormal_fs_single_gene_rec.raw_fields['moleculartestingtype'] = 'R211.1'
    abnormal_fs_single_gene_rec.raw_fields['genotype'] = 'Generic C4/5'
    abnormal_fs_single_gene_rec.raw_fields['report'] = 'This patient has been screened for variants in the following cancer ' \
                                                       'predisposing genes by sequence analysis: APC, BMPR1A, EPCAM*, GREM1*, MLH1, MSH2, MSH6, MUTYH, NTHL1, PMS2, POLD1, ' \
                                                       'POLE, PTEN, RNF43, SMAD4, STK11. This patient is heterozygous for the pathogenic NTHL1 variants c. c.268C>T p.(Gln90Ter) ' \
                                                       'and c.390C>A (p.Tyr130Ter). Assuming that the variants are in trans, this confirms a clinical diagnosis' \
                                                       'of NTHL1-associated polyposis (FAP3). Testing of relatives to confirm phase of these mutations may be appropriate. This ' \
                                                       'patient may be at risk of developing further NTHL1-associated cancers.'

    @handler.populate_variables(abnormal_fs_single_gene_rec)
    @handler.add_varclass
    @handler.add_scope(@genotype, abnormal_fs_single_gene_rec)
    genotypes = @handler.process_variants_from_record(@genotype, abnormal_fs_single_gene_rec)

    assert_equal 17, genotypes.size # NTHL1 gets two as 2 variants

    assert_nil genotypes[0].attribute_map['variantpathclass']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
    assert_equal 358, genotypes[0].attribute_map['gene']

    assert_nil genotypes[1].attribute_map['variantpathclass']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 577, genotypes[1].attribute_map['gene']

    assert_equal 5, genotypes[15].attribute_map['variantpathclass']
    assert_equal 2, genotypes[15].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[15].attribute_map['genetictestscope']
    assert_equal 3108, genotypes[15].attribute_map['gene']
    assert_equal 'c.268C>T', genotypes[15].attribute_map['codingdnasequencechange']
    assert_equal 'p.Gln90Ter', genotypes[15].attribute_map['proteinimpact']

    assert_equal 5, genotypes[16].attribute_map['variantpathclass']
    assert_equal 2, genotypes[16].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[16].attribute_map['genetictestscope']
    assert_equal 3108, genotypes[16].attribute_map['gene']
    assert_equal 'c.390C>A', genotypes[16].attribute_map['codingdnasequencechange']
    assert_equal 'p.Tyr130Ter', genotypes[16].attribute_map['proteinimpact']
  end

  test 'abnormal multi gene record' do
    abnormal_fs_multi_gene_rec = build_raw_record('pseudo_id1' => 'bob')
    abnormal_fs_multi_gene_rec.raw_fields['moleculartestingtype'] = 'R211.1'
    abnormal_fs_multi_gene_rec.raw_fields['genotype'] = 'Generic C4/5'
    abnormal_fs_multi_gene_rec.raw_fields['report'] = 'This patient has been screened for variants in the following cancer ' \
                                                      'predisposing genes by sequence and dosage analysis: APC, BMPR1A, EPCAM*, GREM1*, MLH1, MSH2, MSH6, MUTYH, NTHL1, PMS2, ' \
                                                      'POLD1, POLE, PTEN, SMAD4, STK11. This patient is heterozygous for the MSH2 sequence variant c.1571G>C p.(Arg524Pro). ' \
                                                      'This variant is absent in population control datasets¹, but it has previously been detected in one patient with ' \
                                                      'Muir-Torre syndrome reported in the literature and in multiple patients reported on the ClinVar database². Functional ' \
                                                      'studies suggest it has a deleterious effect on protein function³. It is therefore likely to be pathogenic. This result ' \
                                                      'is consistent with a diagnosis of Lynch syndrome, and this patient is at risk of developing further MSH2-associated cancer. ' \
                                                      'This result may have important implications for relatives, and testing is now available as appropriate if these individuals are ' \
                                                      'referred by their local Clinical Genetics department. This patient is also heterozygous for the MSH6 variant c.899G>A p.(Arg300Gln).'

    @handler.populate_variables(abnormal_fs_multi_gene_rec)
    @handler.add_varclass
    @handler.add_scope(@genotype, abnormal_fs_multi_gene_rec)
    genotypes = @handler.process_variants_from_record(@genotype, abnormal_fs_multi_gene_rec)

    assert_equal 15, genotypes.size

    assert_nil genotypes[0].attribute_map['variantpathclass']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
    assert_equal 358, genotypes[0].attribute_map['gene']

    assert_nil genotypes[12].attribute_map['variantpathclass']
    assert_equal 1, genotypes[12].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[12].attribute_map['genetictestscope']
    assert_equal 76, genotypes[12].attribute_map['gene']

    assert_nil genotypes[13].attribute_map['variantpathclass']
    assert_equal 2, genotypes[13].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[13].attribute_map['genetictestscope']
    assert_equal 2804, genotypes[13].attribute_map['gene']
    assert_equal 'c.1571G>C', genotypes[13].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg524Pro', genotypes[13].attribute_map['proteinimpact']

    assert_nil genotypes[14].attribute_map['variantpathclass']
    assert_equal 2, genotypes[14].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[14].attribute_map['genetictestscope']
    assert_equal 2808, genotypes[14].attribute_map['gene']
    assert_equal 'c.899G>A', genotypes[14].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg300Gln', genotypes[14].attribute_map['proteinimpact']
  end

  private

  def clinical_json
    { sex: '1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2010-08-05T00:00:00.000+01:00',
      authoriseddate: '2010-09-17T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2010-08-05T00:00:00.000+01:00',
      genetictestscope: 'Diagnostic',
      specimentype: '5',
      report: 'Analysis showed that this patient is heterozygous for the pathogenic ' \
              'APC mutation c.847C>T (p.Arg283X). ' \
              'This confirms a clinical diagnosis of FAP.\n\nThis result has important implications ' \
              'for other family members at risk and testing may be performed as appropriate.',
      requesteddate: '2010-08-05T00:00:00.000+01:00',
      age: 99999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'M',
      'reffac.name' => 'Reffac Address',
      provider_address: 'Provider Address',
      providercode: 'Provider Code',
      referringclinicianname: 'Clinician Name',
      consultantcode: 'Consultant Code',
      servicereportidentifier: 'Service Report Identifier',
      patienttype: 'NHS',
      moleculartestingtype: 'Diagnostic',
      indicationcategory: '17510',
      genotype: 'Diagnostic APC +ve',
      report: 'Analysis showed that this patient is heterozygous for the pathogenic ' \
              'APC mutation c.847C>T (p.Arg283X). This confirms a clinical diagnosis of FAP.\n\n' \
              'This result has important implications for other family members at risk and testing ' \
              'may be performed as appropriate.',
      receiveddate: '2010-08-05 00:00:00',
      requesteddate: '2010-08-05 00:00:00',
      authoriseddate: '2010-09-17 00:00:00',
      specimentype: 'Blood' }.to_json
  end
end
