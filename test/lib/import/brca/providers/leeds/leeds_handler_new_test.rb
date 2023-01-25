require 'test_helper'

class LeedsHandlerNewTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Leeds::LeedsHandlerNew.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_abnormal_fs_record' do
    @handler.populate_variables(@record)
    @handler.add_moleculartestingtype(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
    
    @handler.process_genetictestcope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    
    @handler.assign_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    
    genotypes = @handler.process_variants_from_record(@genotype, @record)
    assert_equal 2, genotypes.size
    
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    
    assert_equal 'c.5198A>G', genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[1].attribute_map['codingdnasequencechange']
    
    assert_equal 'p.Asp1733Gly', genotypes[0].attribute_map['proteinimpact']
    assert_nil genotypes[1].attribute_map['proteinimpact']
    
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    
    assert_nil genotypes[0].attribute_map['variantpathclass']

  end

  test 'process_normal_ask_record' do
    norm_ask_record = build_raw_record('pseudo_id1' => 'bob')
    norm_ask_record.raw_fields['moleculartestingtype'] = 'Predictive'
    norm_ask_record.raw_fields['genotype'] = 'Predictive AJ neg 3seq'
    norm_ask_record.raw_fields['report'] = 'Sequence analysis indicates that the familial pathogenic'\
    ' BRCA1 mutation c.68_69del is absent in this patient.\nThis result significantly reduces their risk '\
    'of developing BRCA1-associated cancers. This result does not affect their risk of developing other f'
    @handler.populate_variables(norm_ask_record)
    @handler.add_moleculartestingtype(@genotype, norm_ask_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
    
    @handler.process_genetictestcope(@genotype, norm_ask_record)
    assert_equal 'AJ BRCA screen', @genotype.attribute_map['genetictestscope']
    
    @handler.assign_teststatus(@genotype, norm_ask_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
    
    genotypes = @handler.process_variants_from_record(@genotype, norm_ask_record)
    assert_equal 2, genotypes.size
    
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
  end
  
  test 'process_failed_fs_record' do
    failed_fs_record = build_raw_record('pseudo_id1' => 'bob')
    failed_fs_record.raw_fields['moleculartestingtype'] = nil
    failed_fs_record.raw_fields['genotype'] = nil
    failed_fs_record.raw_fields['report'] = nil
    failed_fs_record.raw_fields['reason'] = 'Diagnostic'
    failed_fs_record.raw_fields['report_result'] = 'NGS screening failed'
    failed_fs_record.raw_fields['firstofreport'] = 'No results were obtained from this sample.\nA repeat '\
    'sample (3-5ml of blood in EDTA or DNA) is therefore requested.'
    @handler.populate_variables(failed_fs_record)
    @handler.add_moleculartestingtype(@genotype, failed_fs_record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
    
    @handler.process_genetictestcope(@genotype, failed_fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    
    @handler.assign_teststatus(@genotype, failed_fs_record)
    assert_equal 9, @genotype.attribute_map['teststatus']
    
    genotypes = @handler.process_variants_from_record(@genotype, failed_fs_record)
    assert_equal 2, genotypes.size
    
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 9, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    
    assert_nil genotypes[0].attribute_map['variantpathclass']
    assert_nil genotypes[1].attribute_map['variantpathclass']
  end
  
  test 'process_targeted_rec' do 
    targ_abnormal_record = build_raw_record('pseudo_id1' => 'bob')
    targ_abnormal_record.raw_fields['moleculartestingtype'] = 'Familial'
    targ_abnormal_record.raw_fields['genotype'] = 'Predictive BRCA1 seq pos'
    targ_abnormal_record.raw_fields['report'] = 'MLPA analysis indicates that this patient is heterozygous for the pathogenic '\
    "BRCA1 duplication of exon 13. This result significantly increases this patient's risk of developing " \
    'BRCA1-associated cancers.\n\nThis result may have important implications for rel'
    @handler.populate_variables(targ_abnormal_record)
    @handler.add_moleculartestingtype(@genotype, targ_abnormal_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
    
    @handler.process_genetictestcope(@genotype, targ_abnormal_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
    
    @handler.assign_teststatus(@genotype, targ_abnormal_record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    
    genotypes = @handler.process_variants_from_record(@genotype, targ_abnormal_record)
    assert_equal 1, genotypes.size
    
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal '13', genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 4, genotypes[0].attribute_map['sequencevarianttype']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['variantpathclass']
  end
  
  test 'process_multigene_report_record' do
    multi_gene_rec = build_raw_record('pseudo_id1' => 'bob')
    multi_gene_rec.raw_fields['moleculartestingtype'] = 'Diagnostic'
    multi_gene_rec.raw_fields['genotype'] = 'B1 Class 5 UV - MLPA'
    multi_gene_rec.raw_fields['report'] = 'This patient has been screened for BRCA1 and BRCA2 mutations by'\
    ' sequence analysis and MLPA.\n\nThis patient is heterozygous for a pathogenic BRCA1 deletion involving exon 3.'\
    ' This result is consistent with '
    @handler.populate_variables(multi_gene_rec)
    @handler.process_genetictestcope(@genotype, multi_gene_rec)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    @handler.assign_teststatus(@genotype, multi_gene_rec)
    genotypes = @handler.process_variants_from_record(@genotype, multi_gene_rec)
    assert_equal 2, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 5, genotypes[0].attribute_map['variantpathclass']
    assert_equal '3', genotypes[0].attribute_map['exonintroncodonnumber']
    
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[1].attribute_map['variantpathclass']
  end
  
  test 'process_multivariant_rec' do 
    multi_var_rec = build_raw_record('pseudo_id1' => 'bob')
    multi_var_rec.raw_fields['moleculartestingtype'] = 'Diagnostic'
    multi_var_rec.raw_fields['genotype'] = 'NGS B1 and B2 seq variant'
    multi_var_rec.raw_fields['report'] = 'Analysis indicates that this patient is heterozygous for the sequence variants'\
    ' c.736T>G (p.Leu246Val) in BRCA1 and c.4068G>A (p.Leu1356Leu) in BRCA2. \nThese variants have previously been '\
    'reported on the BIC database as unknown variants. In silico analyses'
    @handler.populate_variables(multi_var_rec)
    @handler.process_genetictestcope(@genotype, multi_var_rec)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    @handler.assign_teststatus(@genotype, multi_var_rec)
    genotypes = @handler.process_variants_from_record(@genotype, multi_var_rec)
    assert_equal 2, genotypes.size
    
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 'c.736T>G', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Leu246Val', genotypes[0].attribute_map['proteinimpact']
    
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[1].attribute_map['variantpathclass']
    assert_equal 'c.4068G>A', genotypes[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Leu1356Leu', genotypes[1].attribute_map['proteinimpact']
    
  end
  
  private

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
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by ' \
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the ' \
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). ' \
              'This variant involves a moderately-conserved protein position. ' \
              'It is found in population control sets at low frequency, ' \
              'and functional studies suggest that ' \
              'the resultant protein is functional². Evaluation of the available evidence regarding the ' \
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of ' \
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
      genotype: 'R207 - Diag C4/5',
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by ' \
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the ' \
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). ' \
              'This variant involves a moderately-conserved protein position. ' \
              'It is found in population control sets at low frequency, and functional studies suggest that ' \
              'the resultant protein is functional². Evaluation of the available evidence regarding the ' \
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of ' \
              'uncertain significance. Therefore, predictive testing is not indicated for relatives.',
      receiveddate: '2019-10-25 00:00:00',
      requesteddate: '2019-10-25 00:00:00',
      authoriseddate: '2019-11-25 00:00:00',
      specimentype: 'Blood' }.to_json
  end

end
