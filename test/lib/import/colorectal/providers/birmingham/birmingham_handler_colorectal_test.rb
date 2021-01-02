require 'test_helper'
require 'import/genotype.rb'
require 'import/colorectal/core/genotype_mmr.rb'
require 'import/brca/core/provider_handler'
require 'import/storage_manager/persister'

class BirminghamHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Birmingham::BirminghamHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestscope' do
    @handler.process_genetictestscope(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'process_multiple_tests_from_fullscreen' do
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found MLH1 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('Found MSH2 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('Found PMS2 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('Found EPCAM for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    assert_equal 5, @handler.process_variants_from_report(@genotype, @record).size
    #assert_equal 'p.Lys145Asn', @handler.process_variants_from_report(@genotype, @record)[4].attribute_map['proteinimpact']
  end

  test 'process_mutation_from_fullscreen' do
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found MLH1 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('Found MSH2 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('Found PMS2 for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('Found EPCAM for list ["MLH1", "MSH2", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    assert_equal 'p.Lys145Asn', @handler.process_variants_from_report(@genotype, @record)[4].attribute_map['proteinimpact']
  end




  # TODO: write test coverage for function 'summarize'

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
    { sex:'1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-10-17T00:00:00.000+01:00',
      authoriseddate: '2020-03-14T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2019-10-17T00:00:00.000+01:00',
      moleculartestingtype: '1',
      specimentype: '12',
      report: 'Next Generation Sequencing of coding regions in MSH2 (NM_000251.2) and MSH6 (NM_000179.2) (Illumina TruSight Hereditary Cancer Panel). WMRGL universal bioinformatics pipeline v0.5.2 (minimum sequencing depth 20x within exons and +/-5bp, calls with an allele frequency below 15% filtered out). Sanger sequencing as required. MLPA analysis of all MSH2 and MSH6 exons to detect whole exon deletions/duplications. MRC-Holland kits P003-D1 and P072-D1. MLPA also detects a recurrent 10MB inversion in MSH2 and 3’ deletions of EPCAM (NM_002354.3). These testing methods may not detect mosaic variants. Sequence nomenclature using HGVS guidelines. Variants classified according to ACGS Best Practice Guidelines 2020. DNA has been stored.',
      age: '999'}.to_json
  end


  def rawtext_clinical_json
    { 'patient id' => '592866',
      sex:  'M',
      servicereportidentifier: 'D19.48049',
      reason: 'Diagnosis (2)',
      moleculartestingtype: 'Diagnosis',
      reportresult: 'TSHC-Lynch missense UV',
      authoriseddate: '2020-03-14 00: 00: 00',
      teststatus: 'Heterozygous missense variant of uncertain significance c.435A\u003eC p.(Lys145Asn) identified in the MSH6 gene.',
      overall2: 'P',
      'sarah class 3' => '#N/A',
      'sarah class 4' => '#N/A',
      'sarah class 5' => '#N/A',
      indication: 'HNPCC',
      receiveddate: '2019-10-17 00: 00: 00',
      specimentype: 'DNA',
      report: 'Next Generation Sequencing of coding regions in MSH2 (NM_000251.2) and MSH6 (NM_000179.2) (Illumina TruSight Hereditary Cancer Panel). WMRGL universal bioinformatics pipeline v0.5.2 (minimum sequencing depth 20x within exons and +/-5bp, calls with an allele frequency below 15% filtered out). Sanger sequencing as required. MLPA analysis of all MSH2 and MSH6 exons to detect whole exon deletions/duplications. MRC-Holland kits P003-D1 and P072-D1. MLPA also detects a recurrent 10MB inversion in MSH2 and 3’ deletions of EPCAM (NM_002354.3). These testing methods may not detect mosaic variants. Sequence nomenclature using HGVS guidelines. Variants classified according to ACGS Best Practice Guidelines 2020. DNA has been stored.',
      ref_fac: 'PCGE',
      city: 'Exeter',
      name: 'Peninsula Clinical Genetics Exeter',
      providercode: 'PCGE',
      'hospital address' => 'Royal Devon \u0026 Exeter Hospital',
      'hospital city' => 'Exeter',
      'hospital name' => 'Peninsula Clinical Genetics Exeter',
      'hospital postcode' => 'EX1 2ED',
      consultantcode: 'JSPN',
      'clinician surname' => 'M',
      'clinician first name' => 'Jacobs-Pearson',
      'clinician role' => 'Clinical Genetics',
      specialty: 'Genetics',
      department: 'CLINICAL GENETICS'}.to_json
  end
end