require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class RoyalMarsdenHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::RoyalMarsden::RoyalMarsdenHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_gene' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @handler.process_gene(@genotype, @record)
    assert_equal 2744, @genotype.attribute_map['gene']
  end

  test 'process_varpathclass' do
    @handler.process_varpathclass(@genotype, @record)
    assert_equal 5, @genotype.attribute_map['variantpathclass']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['variantpathclass'] = nil
    @logger.expects(:debug).with('NO VARIANTPATHCLASS DETECTED')
    @handler.process_varpathclass(@genotype, broken_record)
  end

  test 'process_teststatus' do
    @handler.process_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['teststatus'] = nil
    @logger.expects(:debug).with('UNABLE TO DETERMINE TESTSTATUS')
    @handler.process_teststatus(@genotype, broken_record)
  end

  test 'process_variant' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 67dupG')
    @handler.process_variant(@genotype, @record)
    assert_equal 'c.67dupG', @genotype.attribute_map['codingdnasequencechange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['teststatus'] = nil
    @logger.expects(:debug).with('NO VARIANT DETECTED')
    @handler.process_variant(@genotype, broken_record)
    protein_record = build_raw_record('pseudo_id1' => 'bob')
    protein_record.raw_fields['teststatus'] = 'c.1483C>T_p.Arg495X'
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1483C>T')
    @logger.expects(:debug).with('SUCCESSFUL protein impact parse for: Arg495X')
    @handler.process_variant(@genotype, protein_record)
  end

  test 'process_test_scope' do
    @handler.process_test_scope(@genotype, @record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
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

  def build_raw_record(options = {})
    default_options = { 'pseudo_id1' => '',
                        'pseudo_id2' => '',
                        'encrypted_demog' => '',
                        'clinical.to_json' => clinical_json,
                        'encrypted_rawtext_demog' => '',
                        'rawtext_clinical.to_json' => rawtext_clinical_json }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { hospitalnumber: 'affected',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      servicereportidentifier: '123456',
      sortdate: '2012-02-01T00:00:00.000+01:00',
      genetictestscope: 'specific mutation',
      gene: '2744',
      variantpathclass: 'Pathogenic mutation',
      age: '999' }.to_json
  end

  def rawtext_clinical_json
    { sid: '123456',
      hospitalnumber: '123456',
      moleculartestingtype: 'affected',
      familyhistory: 'yes',
      cancer1: 'CRC',
      agecancer1: '999',
      cancer2: '',
      agecancer2: '',
      gene: 'MLH1',
      teststatus: 'c.67dupG',
      zygosity: 'Het',
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
      genetictestscope: 'specific mutation' }.to_json
  end
end
