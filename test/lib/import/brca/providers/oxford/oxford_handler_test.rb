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
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['scope / limitations of test'] = 'proband'
    @handler.assign_test_scope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
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
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 7928C>T')
    @handler.process_variants(@genotype, @record)
    assert_equal 'c.7928C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 2, @genotype.attribute_map['teststatus']
    exon_variant_record = build_raw_record('pseudo_id1' => 'bob')
    exon_variant_record.mapped_fields['codingdnasequencechange'] = 'Deletion of exon 12-24'
    @handler.process_variants(@genotype, exon_variant_record)
    assert_equal '12-24', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 10, @genotype.attribute_map['sequencevarianttype']
    assert_equal 2, @genotype.attribute_map['teststatus']
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['codingdnasequencechange'] = 'N/A'
    normal_record.mapped_fields['codingdnasequencechange'] = 'N/A'
    @handler.process_variants(@genotype, normal_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
    exemptions_record = build_raw_record('pseudo_id1' => 'bob')
    exemptions_record.mapped_fields['codingdnasequencechange'] = 'c.[-835C>T]+[=]'
    @handler.process_variants(@genotype, exemptions_record)
    assert_equal 'c.-835C>T', @genotype.attribute_map['codingdnasequencechange']
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
