require 'test_helper'
# require 'import/genotype.rb'
# require 'import/brca/core/provider_handler'

class NottinghamHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Nottingham::NottinghamHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
    @logger.level = Logger::WARN
  end

  test 'process_cdna_change' do
    @handler.process_cdna_or_exonic_variants(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal 'c.8492T>C', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_exonic_variant' do
    exonicvariant_record = build_raw_record('pseudo_id1' => 'bob')
    exonicvariant_record.raw_fields['genotype'] = 'BRCA1 exons 1-2 deletion'
    @handler.process_cdna_or_exonic_variants(@genotype, exonicvariant_record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal '1-2', @genotype.attribute_map['exonintroncodonnumber']
  end

  test 'process_varpathclass' do
    @handler.process_varpathclass(@genotype, @record)
    assert_equal 3, @genotype.attribute_map['variantpathclass']
  end

  test 'assign_test_scope' do
    @handler.assign_test_scope(@record, @genotype)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'assign_conditional_test_scope' do
    conditionaltestscope_record = build_raw_record('pseudo_id1' => 'bob')
    conditionaltestscope_record.raw_fields['disease'] = 'TP53'
    conditionaltestscope_record.raw_fields['moleculartestingtype'] = 'Predictive'
    @handler.assign_test_scope(conditionaltestscope_record, @genotype)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
  end

  test 'assign_conditional_test_status' do
    positivetest_normalgenotype_record = build_raw_record('pseudo_id1' => 'bob')
    positivetest_normalgenotype_record.raw_fields['teststatus'] = 'Normal'
    @handler.assign_test_status(positivetest_normalgenotype_record, @genotype)
    assert_equal 2, @genotype.attribute_map['teststatus']

    positivetest_nogenotype_record = build_raw_record('pseudo_id1' => 'bob')
    positivetest_nogenotype_record.raw_fields['teststatus'] = 'Normal'
    positivetest_nogenotype_record.raw_fields['genotype'] = ''
    @handler.assign_test_status(positivetest_nogenotype_record, @genotype)
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'process_protein_impat' do
    @handler.process_protein_impact(@genotype, @record)
    assert_equal 'p.Met283Thr', @genotype.attribute_map['proteinimpact']
  end

  test 'process_gene' do
    @handler.process_gene(@genotype, @record)
    assert_equal 8, @genotype.attribute_map['gene']
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-03-28T00: 00: 00.000+00: 00',
      authoriseddate: '2019-05-08T00: 00: 00.000+01: 00',
      sortdate: '2019-03-28T00: 00: 00.000+00: 00',
      genetictestscope: 'Diagnostic',
      specimentype: '5',
      gene: '8',
      requesteddate: '2019-03-28T00: 00: 00.000+00: 00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      patient_type: 'NHS',
      disease: 'Hereditary Breast and Ovarian Cancer (BRCA1/BRCA2)',
      moleculartestingtype: 'Diagnostic',
      gene: 'BRCA2',
      genotype: 'c.8492T>C p.(Met283Thr)',
      teststatus: '3:  variant of unknown significance (VUS)',
      requesteddate: '2019-03-28 00: 00: 00',
      receiveddate: '2019-03-28 00: 00: 00',
      specimentype: 'Whole Blood',
      authoriseddate: '2019-05-08 14: 08: 46' }.to_json
  end
end
