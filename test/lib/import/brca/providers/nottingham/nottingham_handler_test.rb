require 'test_helper'
#require 'import/genotype.rb'
#require 'import/brca/core/provider_handler'

class NottinghamHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Nottingham::NottinghamHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 8492T>C')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal 'c.8492T>C', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_varpathclass' do
    @logger.expects(:debug).with('SUCCESSFUL variantpathclass parse for: 3')
    @handler.process_varpathclass(@genotype, @record)
    assert_equal 3, @genotype.attribute_map['variantpathclass']
  end

  test 'process_gene' do
    @handler.process_gene(@genotype, @record)
    assert_equal 8, @genotype.attribute_map['gene']
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
      receiveddate: '2019-03-28T00: 00: 00.000+00: 00',
      authoriseddate: '2019-05-08T00: 00: 00.000+01: 00',
      sortdate: '2019-03-28T00: 00: 00.000+00: 00',
      genetictestscope: 'Diagnostic',
      specimentype: '5',
      gene: '8',
      requesteddate: '2019-03-28T00: 00: 00.000+00: 00',
      age: 999 } .to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      patient_type: 'NHS',
      disease: 'hereditary breast and ovarian cancer (brca1/brca2)',
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
