require 'test_helper'

class OxfordHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Oxford::OxfordHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'assign_servicereportidentifier' do
    @handler.assign_servicereportidentifier(@genotype, @record)
    assert_equal '123456', @genotype.attribute_map['servicereportidentifier']
  end

  test 'assign_varpathclass' do
    @handler.extract_variantpathclass(@genotype, @record)
    assert_equal 3, @genotype.attribute_map['variantpathclass']
    varpath_record = build_raw_record('pseudo_id1' => 'bob')
    varpath_record.mapped_fields['variantpathclass'] = 'C4'
    @handler.extract_variantpathclass(@genotype, varpath_record)
    assert_equal 4, @genotype.attribute_map['variantpathclass']

    varpath_record = build_raw_record('pseudo_id1' => 'bob')
    varpath_record.mapped_fields['variantpathclass'] = '10'
    @handler.extract_variantpathclass(@genotype, varpath_record)
    assert_nil @genotype.attribute_map['variantpathclass']
  end

  test 'assign_test_type' do
    @handler.assign_test_type(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
    pre_symto_record = build_raw_record('pseudo_id1' => 'bob')
    pre_symto_record.raw_fields['moleculartestingtype'] = 'pre-symptomatic'
    @handler.assign_test_type(@genotype, pre_symto_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
  end

  test 'assign_test_scope' do
    @handler.assign_test_scope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    targeted_record1 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record1.raw_fields['scope / limitations of test'] = 'targeted'
    @handler.assign_test_scope(@genotype, targeted_record1)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    targeted_record2 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record2.raw_fields['scope / limitations of test'] = 'RD proband confirmation'
    @handler.assign_test_scope(@genotype, targeted_record2)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    targeted_record3 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record3.raw_fields['scope / limitations of test'] = 'HNPCC Familial'
    @handler.assign_test_scope(@genotype, targeted_record3)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    targeted_record4 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record4.raw_fields['scope / limitations of test'] = 'c.1100 only'
    @handler.assign_test_scope(@genotype, targeted_record4)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    no_scope_record = build_raw_record('pseudo_id1' => 'bob')
    no_scope_record.raw_fields['scope / limitations of test'] = 'no scope'
    @handler.assign_test_scope(@genotype, no_scope_record)
    assert_equal 'Unable to assign BRCA genetictestscope', @genotype.attribute_map['genetictestscope']

    full_screen_record1 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record1.raw_fields['scope / limitations of test'] = 'panel'
    @handler.assign_test_scope(@genotype, full_screen_record1)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record2 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record2.raw_fields['scope / limitations of test'] = 'fullscreen'
    @handler.assign_test_scope(@genotype, full_screen_record2)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record3 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record3.raw_fields['scope / limitations of test'] = 'full screem'
    @handler.assign_test_scope(@genotype, full_screen_record3)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record4 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record4.raw_fields['scope / limitations of test'] = 'full gene screen'
    @handler.assign_test_scope(@genotype, full_screen_record4)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record5 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record5.raw_fields['scope / limitations of test'] = 'brca_multiplicom'
    @handler.assign_test_scope(@genotype, full_screen_record5)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record6 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record6.raw_fields['scope / limitations of test'] = 'hcs'
    @handler.assign_test_scope(@genotype, full_screen_record6)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record7 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record7.raw_fields['scope / limitations of test'] = 'brca1'
    @handler.assign_test_scope(@genotype, full_screen_record7)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record8 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record8.raw_fields['scope / limitations of test'] = 'brca2'
    @handler.assign_test_scope(@genotype, full_screen_record8)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record9 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record9.raw_fields['scope / limitations of test'] = 'cnv only'
    @handler.assign_test_scope(@genotype, full_screen_record9)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record10 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record10.raw_fields['scope / limitations of test'] = 'CNV analysis'
    @handler.assign_test_scope(@genotype, full_screen_record10)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record11 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record11.raw_fields['scope / limitations of test'] = 'SNV analysis ONLY'
    @handler.assign_test_scope(@genotype, full_screen_record11)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    full_screen_record12 = build_raw_record('pseudo_id1' => 'bob')
    full_screen_record12.raw_fields['scope / limitations of test'] = 'whole gene screen'
    @handler.assign_test_scope(@genotype, full_screen_record12)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'process_gene' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for 8')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for:8')
    @handler.process_gene(@genotype, @record)
    assert_equal 8, @genotype.attribute_map['gene']
    synonym_record = build_raw_record('pseudo_id1' => 'bob')
    synonym_record.mapped_fields['gene'] = 'Cabbage'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for:BRCA2')
    @handler.process_gene(@genotype, synonym_record)
    assert_equal 8, @genotype.attribute_map['gene']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['gene'] = 'Cabbage'
    broken_record.raw_fields['sinonym'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED gene parse')
    @handler.process_gene(@genotype, broken_record)
    chek2_record = build_raw_record('pseudo_id1' => 'bob')
    chek2_record.mapped_fields['gene'] = '865'
    chek2_record.raw_fields['gene'] = 'CHEK2'
    chek2_record.raw_fields['sinonym'] = 'Cabbage'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for 865')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for:865')
    @handler.process_gene(@genotype, chek2_record)
  end

  test 'process_variants' do
    @handler.process_variants(@genotype, @record, 5)
    assert_equal 'c.7928C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 2, @genotype.attribute_map['teststatus']
    exon_variant_record = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record.mapped_fields['codingdnasequencechange'] = 'Deletion of exon 12-24'
    @handler.process_variants(@genotype, exon_variant_record, 5)
    assert_equal '12-24', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['codingdnasequencechange'] = 'N/A'
    normal_record.mapped_fields['codingdnasequencechange'] = 'N/A'
    @handler.process_variants(@genotype, normal_record, 5)
    assert_equal 1, @genotype.attribute_map['teststatus']
    exemptions_record = build_raw_record('pseudo_id1' => 'bob')
    exemptions_record.mapped_fields['codingdnasequencechange'] = 'c.[-835C>T]+[=]'
    @handler.process_variants(@genotype, exemptions_record, 5)
    assert_equal 'c.-835C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 2, @genotype.attribute_map['teststatus']

    @handler.process_variants(@genotype, @record, 2)
    assert_equal 'c.7928C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 10, @genotype.attribute_map['teststatus']

    exon_variant_record2 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record2.mapped_fields['codingdnasequencechange'] = 'ex1-2 deletion'
    @handler.process_variants(@genotype, exon_variant_record2, 5)
    assert_equal '1-2', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record3 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record3.mapped_fields['codingdnasequencechange'] = 'ex3 dup'
    @handler.process_variants(@genotype, exon_variant_record3, 5)
    assert_equal '3', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record4 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record4.mapped_fields['codingdnasequencechange'] = 'ex4+5 deletion'
    @handler.process_variants(@genotype, exon_variant_record4, 5)
    assert_equal '4+5', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record5 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record5.mapped_fields['codingdnasequencechange'] = 'deletion BRCA1 exons 6-7'
    @handler.process_variants(@genotype, exon_variant_record5, 5)
    assert_equal '6-7', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record6 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record6.mapped_fields['codingdnasequencechange'] = 'exon 8-exon 9 del'
    @handler.process_variants(@genotype, exon_variant_record6, 5)
    assert_equal '8-9', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record7 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record7.mapped_fields['codingdnasequencechange'] = 'BRCA1 ex 10-11 dup'
    @handler.process_variants(@genotype, exon_variant_record7, 5)
    assert_equal '10-11', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record8 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record8.mapped_fields['codingdnasequencechange'] = 'Exon 12 duplication'
    @handler.process_variants(@genotype, exon_variant_record8, 5)
    assert_equal '12', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record9 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record9.mapped_fields['codingdnasequencechange'] = 'Exons 13-14 duplication'
    @handler.process_variants(@genotype, exon_variant_record9, 5)
    assert_equal '13-14', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record10 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record10.mapped_fields['codingdnasequencechange'] = 'duplication exon 15'
    @handler.process_variants(@genotype, exon_variant_record10, 5)
    assert_equal '15', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record11 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record11.mapped_fields['codingdnasequencechange'] = 'duplication of exons 16-17'
    @handler.process_variants(@genotype, exon_variant_record11, 5)
    assert_equal '16-17', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record12 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record12.mapped_fields['codingdnasequencechange'] = 'deletion exons 18-19'
    @handler.process_variants(@genotype, exon_variant_record12, 5)
    assert_equal '18-19', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record13 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record13.mapped_fields['codingdnasequencechange'] = 'deletion of exon 20'
    @handler.process_variants(@genotype, exon_variant_record13, 5)
    assert_equal '20', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record14 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record14.mapped_fields['codingdnasequencechange'] = 'exon 21 deletion'
    @handler.process_variants(@genotype, exon_variant_record14, 5)
    assert_equal '21', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']

    exon_variant_record15 = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record15.mapped_fields['codingdnasequencechange'] = 'exons 22-23 deletion'
    @handler.process_variants(@genotype, exon_variant_record15, 1)
    assert_equal '22-23', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 10, @genotype.attribute_map['teststatus']

    nonpath_exon_variant_record = build_raw_record('pseudo_id1' => 'bob')
    nonpath_exon_variant_record.mapped_fields['codingdnasequencechange'] = 'Deletion of exon 12-24'
    @handler.process_variants(@genotype, nonpath_exon_variant_record, 2)
    assert_equal '12-24', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal 10, @genotype.attribute_map['teststatus']

    exemptions_del_record1 = build_raw_record('pseudo_id1' => 'bob')
    exemptions_del_record1.mapped_fields['codingdnasequencechange'] = 'Deletion of whole PTEN gene'
    @handler.process_variants(@genotype, exemptions_del_record1, 5)
    assert_equal 2, @genotype.attribute_map['teststatus']

    exemptions_del_record2 = build_raw_record('pseudo_id1' => 'bob')
    exemptions_del_record2.mapped_fields['codingdnasequencechange'] = 'whole gene duplication'
    @handler.process_variants(@genotype, exemptions_del_record2, 5)
    assert_equal 2, @genotype.attribute_map['teststatus']

    path_exemptions_record = build_raw_record('pseudo_id1' => 'bob')
    path_exemptions_record.mapped_fields['codingdnasequencechange'] = 'c.( 442-127_ 593+118)'
    path_exemptions_record.mapped_fields['variantpathclass'] = 'C4'
    variantpathclass = @handler.extract_variantpathclass(@genotype, path_exemptions_record)
    @handler.process_variants(@genotype, path_exemptions_record, variantpathclass)
    assert_equal 'c.442-127_593+118', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 4, @genotype.attribute_map['variantpathclass']
    assert_equal 2, @genotype.attribute_map['teststatus']

    path_rec = build_raw_record('pseudo_id1' => 'bob')
    path_rec.mapped_fields['codingdnasequencechange'] = 'c.[-169C>T]+[=]'
    path_rec.mapped_fields['variantpathclass'] = 'C3'
    variantpathclass = @handler.extract_variantpathclass(@genotype, path_rec)
    @handler.process_variants(@genotype, path_rec, variantpathclass)
    assert_equal 'c.-169C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 3, @genotype.attribute_map['variantpathclass']
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'process_protein_impact' do
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Ala2643Val')
    @handler.process_protein_impact(@genotype, @record)
    assert_equal 'p.Ala2643Val', @genotype.attribute_map['proteinimpact']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['proteinimpact'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED protein change parse')
    @handler.process_protein_impact(@genotype, broken_record)
  end

  test 'assign_genomic_change' do
    @handler.assign_genomic_change(@genotype, @record)
    assert_equal '13:32936782', @genotype.attribute_map['genomicchange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = 'Cabbage'
    @logger.expects(:warn).with('Could not process, so adding raw genomic change: Cabbage')
    @handler.assign_genomic_change(@genotype, broken_record)
  end

  private

  def clinical_json
    { sex: '2',
      hospitalnumber: 'Hospital Number',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      sortdate: '2017-08-17T00: 00: 00.000+01: 00',
      karyotypingmethod: '17',
      specimentype: '5',
      gene: '8',
      referencetranscriptid: 'NM_000059.3',
      genomicchange: 'Chr13.hg19: g.32936782',
      codingdnasequencechange: 'c.[7928C>T]+[=]',
      proteinimpact: 'p.[Ala2643Val]+[=]',
      variantpathclass: '3',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      providercode: 'Provider Code',
      consultantname: 'Consultant Name',
      investigationid: '123456',
      service_level: 'routine',
      collceteddate: 'N/A',
      requesteddate: '2017-08-17 00: 00: 00',
      receiveddate: '2017-08-17 00: 00: 00',
      authoriseddate: '2017-10-11 16: 42: 37',
      moleculartestingtype: 'diagnostic',
      'scope / limitations of test' => 'BRCA_Multiplicom',
      gene: 'BRCA2',
      referencetranscriptid: 'NM_000059.3',
      genomicchange: 'Chr13.hg19:g.32936782',
      codingdnasequencechange: 'c.[7928C>T]+[=]',
      proteinimpact: 'p.[Ala2643Val]+[=]',
      variantpathclass: '3',
      'clinical implications / conclusions' => nil,
      specimentype: 'BLOOD',
      karyotypingmethod: 'Sequencing, Next Generation Panel (NGS)',
      'origin of mutation / rearrangement' => nil,
      'percentage mutation allele / abnormal karyotye' => nil,
      sinonym: 'A_BRCA2-17______' }.to_json
  end
end
