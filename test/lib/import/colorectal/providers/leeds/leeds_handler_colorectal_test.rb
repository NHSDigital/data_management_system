require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class LeedsHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Leeds::LeedsHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'add_positive_teststatus' do
    @logger.expects(:debug).with('Cannot determine test status for : Diagnostic APC +ve a priori')
    @handler.add_positive_teststatus(@genotype, @record)
  end

  test 'failed_teststatus' do
    @logger.expects(:debug).with('Cannot determine test status for : Analysis showed that this '\
    'patient is heterozygous for the pathogenic APC mutation c.847C>T (p.Arg283X). '\
    'This confirms a clinical diagnosis of FAP.\n\nThis result has important implications for '\
    'other family members at risk and testing may be performed as appropriate. a priori')
    @handler.failed_teststatus(@genotype, @record)
  end

  test 'add_gene_from_report' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: APC')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 847C>T')
    @logger.expects(:debug).with('SUCCESSFUL protein impact parse for: Arg283X')
    @handler.add_gene_from_report(@genotype, @record)
    assert_equal 'c.847C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg283x', @genotype.attribute_map['proteinimpact']
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['report'] = 'This patient has been screened for MLH1, MSH2, MSH6 and '\
    'PMS2 mutations by sequence and dosage analysis. No pathogenic mutation was identified.'\
    '\n\n\n\nThis result does not exclude a diagnosis of Lynch syndrome.\n\nTesting for other '\
    'genes involved in familial bowel cancer is available if appropriate.'
    normal_record.mapped_fields['report'] = 'This patient has been screened for MLH1, MSH2, MSH6 and '\
    'PMS2 mutations by sequence and dosage analysis. No pathogenic mutation was identified.'\
    '\n\n\n\nThis result does not exclude a diagnosis of Lynch syndrome.\n\nTesting for other '\
    'genes involved in familial bowel cancer is available if appropriate.'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["MLH1"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["MSH2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["MSH6"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["PMS2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    assert_equal 4, @handler.add_gene_from_report(@genotype, normal_record).size
  end

  test 'process_scope' do
    @handler.process_scope(@record.mapped_fields['genetictestscope'], @genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  private

  def clinical_json
    { sex: '1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2010-08-05T00:00:00.000+01:00',
      authoriseddate: '2010-09-17T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2010-08-05T00:00:00.000+01:00',
      genetictestscope: 'Diagnostic',
      specimentype: '5',
      report: 'Analysis showed that this patient is heterozygous for the pathogenic'\
              ' APC mutation c.847C>T (p.Arg283X). '\
              'This confirms a clinical diagnosis of FAP.\n\nThis result has important implications '\
              'for other family members at risk and testing may be performed as appropriate.',
      requesteddate: '2010-08-05T00:00:00.000+01:00',
      age: 99999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'M',
      'reffac.name' => 'Reffac Address',
      provider_address: 'Provider Address',
      providercode: 'Provider Code',
      referringclinicianname: 'Clinician Name',
      consultantcode: 'Consultant Code',
      servicereportidentifier: 'Service Report Identifier',
      patienttype: 'NHS',
      moleculartestingtype: 'Diagnostic',
      indicationcategory: '17510',
      genotype: 'Diagnostic APC +ve',
      report: 'Analysis showed that this patient is heterozygous for the pathogenic '\
              'APC mutation c.847C>T (p.Arg283X). This confirms a clinical diagnosis of FAP.\n\n'\
              'This result has important implications for other family members at risk and testing '\
              'may be performed as appropriate.',
      receiveddate: '2010-08-05 00:00:00',
      requesteddate: '2010-08-05 00:00:00',
      authoriseddate: '2010-09-17 00:00:00',
      specimentype: 'Blood' }.to_json
  end
end
