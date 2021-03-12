require 'test_helper'

class SalisburyHandlerTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Salisbury::SalisburyHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'extract_gene' do
    @handler.extract_gene(@record.raw_fields['test'], @genotype)
    assert_equal 8, @genotype.attribute_map['gene']
  end

  test 'extract_teststatus' do
    @handler.extract_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['status'] = 'Failed'
    @handler.extract_teststatus(@genotype, broken_record)
    assert_equal 9, @genotype.attribute_map['teststatus']
  end

  test 'extract_variant' do
    @handler.extract_variant(@record.raw_fields['genotype'], @genotype)
    assert_equal 'c.9382C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg3128Ter', @genotype.attribute_map['proteinimpact']
    assert_equal 1, @genotype.attribute_map['sequencevarianttype']
  end

  test 'add_organisationcode_testresult' do
    @handler.add_organisationcode_testresult(@genotype)
    assert_equal '699H0', @genotype.attribute_map['organisationcode_testresult']
  end

  private

  # TODO: DRY this method up into a helper
  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_to_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_to_clinical_to_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_to_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      receiveddate: '2017-06-20T00: 00: 00.000+01: 00',
      authoriseddate: '2017-07-25T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      requesteddate: '2017-06-20',
      specimentype: '5',
      age: 999 }.to_json
  end

  def rawtext_to_clinical_to_json
    { sex: 'Female',
      providercode: 'Provider Name',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      service_level: 'NHS',
      moleculartestingtype: 'Breast cancer full screen',
      requesteddate: '2017-06-20 00: 00: 00',
      receiveddate: '2017-06-20 00: 00: 00',
      authoriseddate: '2017-07-25 10: 08: 18',
      specimentype: 'Blood',
      status: 'Pathogenic mutation detected',
      genotype: 'c.9382C>T p.(Arg3128Ter)',
      test: 'BRCA2 mutation analysis' }.to_json
  end
end
