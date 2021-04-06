require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class NewcastleHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Newcastle::NewcastleHandlerColorectal.new(EBatch.new)
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

  test 'process_gene_colorectal' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1569dupT')
    @logger.expects(:debug).with('SUCCESSFUL PROTEIN change parse for: Arg524fs')
    assert_equal 5, @handler.process_gene_colorectal(@genotype, @record).size
    assert_equal 'c.1569dupT', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg524fs', @genotype.attribute_map['proteinimpact']
  end

  test 'process_investigation_code' do
    @logger.expects(:debug).with('Found O/C/0')
    @handler.process_investigation_code(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['service category'] = 'Cabbage'
    targeted_record.raw_fields['moleculartestingtype'] = 'carrier'
    @logger.expects(:debug).with('ADDED SCOPE FROM TYPE')
    @handler.process_investigation_code(@genotype, targeted_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2008-03-11T00:00:00.000+00:00',
      authoriseddate: '2009-11-02T00:00:00.000+00:00',
      sortdate: '2008-03-11T00:00:00.000+00:00',
      specimentype: '5',
      gene: '2804',
      variantpathclass: 'pathogenic',
      requesteddate: '2009-08-14T00:00:00.000+01:00',
      age: 99999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      providercode: 'Provider Address',
      consultantname: 'Clinician Name',
      servicereportidentifier: 'Service Report Identifier',
      'service category' => 'O',
      moleculartestingtype: 'Diagnostic test',
      'investigation code' => 'HNPCC',
      gene: 'MSH2',
      genotype: 'c.1569dupT (p.Arg524fs)',
      variantpathclass: 'pathogenic',
      teststatus: 'het',
      specimentype: 'Blood',
      receiveddate: '2008-03-11 00:00:00',
      requesteddate: '2009-08-14 00:00:00',
      authoriseddate: '2009-11-02 00:00:00' }.to_json
  end
end
