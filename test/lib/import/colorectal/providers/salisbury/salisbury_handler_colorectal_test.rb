require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class SalisburyHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Salisbury::SalisburyHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
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

  test 'extract_variant' do
    @handler.extract_variant(@record.raw_fields['genotype'], @genotype)
    assert_equal 'c.1621A>C', @genotype.attribute_map['codingdnasequencechange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genotype'] = 'Cabbage'
    @logger.expects(:warn).with('Cannot extract gene location from raw test: Cabbage')
    @handler.extract_variant(broken_record.raw_fields['genotype'], @genotype)
    nil_record = build_raw_record('pseudo_id1' => 'bob')
    nil_record.raw_fields['genotype'] = ''
    @handler.extract_variant(nil_record.raw_fields['genotype'], @genotype)
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'add_colorectal_from_raw_test' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene change parse for: MSH6')
    @handler.add_colorectal_from_raw_test(@genotype, @record)
    assert_equal 2808, @genotype.attribute_map['gene']
    multigene_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    @logger.expects(:error).with('Multiple genes detected in input string: MLH1 and MSH2 test;')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @handler.add_colorectal_from_raw_test(@genotype, multigene_record)
    cabbage_record = build_raw_record('pseudo_id1' => 'bob')
    cabbage_record.raw_fields['test'] = 'COO-COO!'
    @logger.expects(:debug).with('FAILED cdna channge parse for  COO-COO!')
    @handler.add_colorectal_from_raw_test(@genotype, cabbage_record)
  end

  test 'extract_teststatus' do
    @logger.expects(:debug).with('POSITIVE status for : Likely pathogenic')
    @handler.extract_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']

    failed_record = build_raw_record('pseudo_id1' => 'bob')
    failed_record.raw_fields['status'] = 'Failed'
    @logger.expects(:debug).with('FAILED status for : Failed')
    @handler.extract_teststatus(@genotype, failed_record)
    assert_equal 9, @genotype.attribute_map['teststatus']

    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['status'] = 'Normal'
    @logger.expects(:debug).with('POSITIVE status for : Normal')
    @handler.extract_teststatus(@genotype, normal_record)
    assert_equal 1, @genotype.attribute_map['teststatus']

    nomut_record = build_raw_record('pseudo_id1' => 'bob')
    nomut_record.raw_fields['status'] = 'No mutation detected'
    @logger.expects(:debug).with('POSITIVE status for : No mutation detected')
    @handler.extract_teststatus(@genotype, nomut_record)
    assert_equal 1, @genotype.attribute_map['teststatus']

    cabbage_record = build_raw_record('pseudo_id1' => 'bob')
    cabbage_record.raw_fields['status'] = 'Cabbage'
    @logger.expects(:debug).with('Cannot determine test status for : Cabbage')
    @handler.extract_teststatus(@genotype, cabbage_record)
  end

  def clinical_json
    { sex: '1',
      consultantcode: 'C9999998',
      providercode: 'RJ1',
      receiveddate: '2018-11-22T00:00:00.000+00:00',
      authoriseddate: '2018-11-29T00:00:00.000+00:00',
      servicereportidentifier: 'W1234567',
      sortdate: '2018-11-22T00:00:00.000+00:00',
      specimentype: '12',
      requesteddate: '2018-11-22T00:00:00.000+00:00',
      age: 56 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Male',
      providercode: 'DNA Laboratory (Guys)',
      consultantname: 'Dr Very Good',
      servicereportidentifier: 'W1234567',
      "service level": 'NHS',
      moleculartestingtype: 'HNPCC predictives',
      requesteddate: '2018-11-22 00:00:00',
      receiveddate: '2018-11-22 00:00:00',
      authoriseddate: '2018-11-29 09:43:13',
      specimentype: 'External D N A',
      status: 'Likely pathogenic',
      genotype: 'c.1621A>C p.(Ser541Arg)',
      test: 'hMSH6 exon 4C' }.to_json
  end
end
