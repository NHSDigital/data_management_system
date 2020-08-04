require 'test_helper'

class SheffieldHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Sheffield::SheffieldHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'add_test_scope' do
    @logger.expects(:debug).with('PERFORMING TEST for function add_test_scope')
    @logger.expects(:debug).with('PERFORMING TEST for: BRCA1 and 2 familial mutation')
    @logger.expects(:debug).with('ADDED TARGETED TEST for: BRCA1 and 2 familial mutation')
    @handler.add_test_scope(@genotype, @record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    fullscreen_record = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_record.mapped_fields['genetictestscope'] = 'Breast Ovarian & Colorectal cancer panel'
    @logger.expects(:debug).with('PERFORMING TEST for function add_test_scope')
    @logger.expects(:debug).with('PERFORMING TEST for: Breast Ovarian & Colorectal cancer panel')
    @logger.expects(:debug).with('ADDED FULL_SCREEN TEST for: Breast Ovarian & Colorectal cancer panel')
    @handler.add_test_scope(@genotype, fullscreen_record)
  end

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
    { sex: '1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      collecteddate: '2018-06-13T00:00:00.000+01:00',
      receiveddate: '2018-06-13T00:00:00.000+01:00',
      authoriseddate: '2018-07-04T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2018-06-13T00:00:00.000+01:00',
      genetictestscope: 'BRCA1 and 2 familial mutation',
      specimentype: '5',
      genotype: 'BRCA2: c.[520C>T];[520=]  p.[(?)];[(=)]',
      age: 63 }.to_json
  end

  def rawtext_to_clinical_to_json
    { sex: 'Male',
      servicereportidentifier: 'Service Report Identifier',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      patienttype: 'NHS',
      moleculartestingtype: 'Predictive testing',
      specimentype: 'Blood',
      collecteddate: '13/06/2018',
      receiveddate: '13/06/2018',
      authoriseddate: '04/07/2018',
      genotype: 'BRCA2: c.[520C>T];[520=]  p.[(?)];[(=)]',
      genetictestscope: 'BRCA1 and 2 familial mutation',
      karyotypingmethod: 'BRCA2 gene sequencing' }.to_json
  end
end
