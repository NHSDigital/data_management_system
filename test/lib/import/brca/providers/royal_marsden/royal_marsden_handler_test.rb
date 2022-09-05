require 'test_helper'

class RoyalMarsdenHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::RoyalMarsden::RoyalMarsdenHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_gene' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for 7')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for:7')
    @handler.process_gene(@genotype, @record)
    assert_equal 7, @genotype.attribute_map['gene']
    badgene_record = build_raw_record('pseudo_id1' => 'bob')
    badgene_record.mapped_fields['gene'] = 2744
    @logger.expects(:debug).with('FAILED gene parse for: 2744')
    @handler.process_gene(@genotype, badgene_record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['gene'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED gene parse for: 0')
    @handler.process_gene(@genotype, broken_record)
  end

  test 'process_varpathclass' do
    @handler.process_varpathclass(@genotype, @record)
    assert_equal 5, @genotype.attribute_map['variantpathclass']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['variantpathclass'] = nil
    @logger.expects(:debug).with('NO VARIANT PATHCLASS DETECTED')
    @handler.process_varpathclass(@genotype, broken_record)
  end

  test 'process_teststatus' do
    @handler.process_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['teststatus'] = nil
    @logger.expects(:debug).with('UNABLE TO DETERMINE TESTSTATUS')
    @handler.process_teststatus(@genotype, broken_record)
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['teststatus'] = 'NO PATHOGENIC VARIANT IDENTIFIED'
    @handler.process_teststatus(@genotype, normal_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'process_variant' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 8149G>T')
    @logger.expects(:debug).with('SUCCESSFUL protein impact parse for: Ala2717Ser')
    @handler.process_variant(@genotype, @record)
    assert_equal 'c.8149G>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Ala2717Ser', @genotype.attribute_map['proteinimpact']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['teststatus'] = nil
    @logger.expects(:debug).with('NO VARIANT DETECTED')
    @handler.process_variant(@genotype, broken_record)
    noprotein_record = build_raw_record('pseudo_id1' => 'bob')
    noprotein_record.raw_fields['teststatus'] = 'c.1483C>T'
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1483C>T')
    @handler.process_variant(@genotype, noprotein_record)
    assert_equal 'c.1483C>T', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_test_scope' do
    nil_record = build_raw_record('pseudo_id1' => 'bob')
    nil_record.raw_fields['genetictestscope'] = nil
    @handler.process_test_scope(@genotype, nil_record)
    assert_nil @genotype.attribute_map['genetictestscope']
    @handler.process_test_scope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['genetictestscope'] = 'specific mutation'
    @handler.process_test_scope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
  end

  test 'process_large_deldup' do
    deldup_record = build_raw_record('pseudo_id1' => 'bob')
    deldup_record.raw_fields['teststatus'] = 'Exon 9-10 deletion'
    @handler.process_large_deldup(@genotype, deldup_record)
    assert_equal '9-10', @genotype.attribute_map['exonintroncodonnumber']
  end

  test 'process_test_type' do
    @handler.process_test_type(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  private

  def clinical_json
    { hospitalnumber: 'affected',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      servicereportidentifier: '123456',
      sortdate: '2012-02-01T00:00:00.000+01:00',
      genetictestscope: 'full gene',
      gene: '7',
      variantpathclass: 'Pathogenic mutation',
      age: '999' }.to_json
  end

  def rawtext_clinical_json
    { sid: '123456',
      hospitalnumber: '123456',
      moleculartestingtype: 'affected',
      familyhistory: 'yes',
      cancer1: 'Breast cancer - triple negative',
      agecancer1: '999',
      cancer2: '',
      agecancer2: '',
      gene: 'BRCA1',
      teststatus: 'c.8149G>T; p.Ala2717Ser',
      zygosity: '',
      variantpathclass: 'Pathogenic mutation',
      exon: '1',
      consultantname: 'Consultant Name',
      providercode: 'Royal Marsden',
      department: 'Department',
      collceteddate: '01/01/2012',
      receiveddate: '2012-02-01 00:00:00',
      requesteddate: '2012-02-01 00:00:00',
      authoriseddate: '2012-02-01 00:00:00',
      servicereportidentifier: '123456',
      genetictestscope: 'full gene' }.to_json
  end
end
