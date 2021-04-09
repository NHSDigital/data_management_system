require 'test_helper'
#require 'import/genotype.rb'
#require 'import/brca/core/provider_handler'

class NewcastleHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Newcastle::NewcastleHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_protein_impact' do
    @logger.expects(:debug).with('FAILED protein change parse for: c.2597G>A')
    @handler.process_protein_impact(@genotype, @record)
    protein_record = build_raw_record('pseudo_id1' => 'bob')
    protein_record.raw_fields['genotype'] = 'c.2597G>A;p.Thr2968fsX8'
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Thr2968fsX8')
    @handler.process_protein_impact(@genotype, protein_record)
    assert_equal 'p.Thr2968fsx8', @genotype.attribute_map['proteinimpact']
  end

  test 'process_investigation_code' do
    @logger.expects(:info).with('Found O')
    @handler.process_investigation_code(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    type_record = build_raw_record('pseudo_id1' => 'bob')
    type_record.raw_fields['service category'] = 'B'
    @logger.expects(:info).with('ADDED SCOPE FROM TYPE')
    @handler.process_investigation_code(@genotype, type_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['service category'] = 'B'
    targeted_record.raw_fields['moleculartestingtype'] = 'Carrier'
    @logger.expects(:info).with('ADDED SCOPE FROM TYPE')
    @handler.process_investigation_code(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
  end

  test 'process_variant_details' do
    @handler.process_variant_details(@genotype, @record)
    assert_equal 3, @genotype.attribute_map['variantpathclass']
  end

  test 'process_test_type' do
    @handler.process_test_type(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  test 'process_raw_genotype' do
    @handler.process_raw_genotype(@genotype, @record)
    genotype = @handler.process_raw_genotype(@genotype, @record)
    assert_equal 1, genotype.size
    other_record = build_raw_record('pseudo_id1' => 'bob')
    other_record.raw_fields['teststatus'] = 'nmd'
    other_record.raw_fields['gene'] = nil
    null_genotype = Import::Brca::Core::GenotypeBrca.new(other_record)
    assert_equal 2, @handler.process_raw_genotype(null_genotype, other_record).size
  end

  test 'add_brca_from_raw_genotype' do
    @handler.add_brca_from_raw_genotype(@genotype, @record)
    assert_equal 7, @genotype.attribute_map['gene']
  end

  test 'add_cdna_change_from_report' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 2597G>A')
    @handler.add_cdna_change_from_report(@genotype, @record)
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
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2006-10-13T00: 00: 00.000+01: 00',
      authoriseddate: '2007-01-02T00: 00: 00.000+00: 00',
      sortdate: '2006-10-13T00: 00: 00.000+01: 00',
      specimentype: '5',
      gene: '7',
      variantpathclass: 'unclassified variant',
      requesteddate: '2006-10-27T00: 00: 00.000+01: 00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Servire Report Identifier',
      'service category' => 'O',
      moleculartestingtype: 'Diagnostic',
      'investigation code' => 'BRCA',
      gene: 'BRCA1',
      genotype: 'c.2597G>A',
      variantpathclass: 'unclassified variant',
      teststatus: 'other',
      specimentype: 'Blood',
      receiveddate: '2006-10-13 00: 00: 00',
      requesteddate: '2006-10-27 00: 00: 00',
      authoriseddate: '2007-01-02 00: 00: 00' }.to_json
  end
end
