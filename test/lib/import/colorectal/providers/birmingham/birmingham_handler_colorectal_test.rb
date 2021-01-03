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

  test 'negative_tests_from_fullscreen' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['overall2'] = 'N'
    @logger.expects(:debug).with('NORMAL TEST FOUND')
    @logger.expects(:debug).with('Found MLH1 for list ["MLH1", "MSH2", "MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('Found MSH2 for list ["MLH1", "MSH2", "MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('Found MSH6 for list ["MLH1", "MSH2", "MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('Found PMS2 for list ["MLH1", "MSH2", "MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('Found EPCAM for list ["MLH1", "MSH2", "MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    assert_equal 5, @handler.process_variants_from_report(@genotype, negative_record).size
  end

  test 'process_tests_from_empty_teststatus' do
    empty_teststatus_record = build_raw_record('pseudo_id1' => 'bob')
    empty_teststatus_record.raw_fields['teststatus'] = 'Cabbage'
    empty_teststatus_record.raw_fields['report'] = 'A mutation in exon 13 of the APC gene, a C to T transition at codon 554, has previously been reported in the Oxford DNA lab- oratory in this patient family. This mutation is detectable by direct PCR/DGGE analysis of exon 13.'
    empty_teststatus_record.raw_fields['indication'] = 'FAP'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    assert_equal 358, @handler.process_variants_from_report(@genotype, empty_teststatus_record).first.attribute_map['gene']
  end

  test 'process_chromosomevariants_from_record' do
    chromovariants_record = build_raw_record('pseudo_id1' => 'bob')
    chromovariants_record.raw_fields['teststatus'] = 'Frameshift mutation in exon 15 of hMSH2 plus missense mutation in exon 1 of hMLH1 identified'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('Found MSH6 for list ["MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('Found PMS2 for list ["MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('Found EPCAM for list ["MSH6", "PMS2", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    assert_equal 5, @handler.process_variants_from_report(@genotype, chromovariants_record).size
  end

  test 'process_mutyh_specific_single_cdna_variants' do
    mutyh_record = build_raw_record('pseudo_id1' => 'bob')
    mutyh_record.raw_fields['teststatus'] = 'Homozygous for the MYH gene mutation c.527A\\u003eG, p.Tyr176Cys.'
    mutyh_record.raw_fields['indication'] = 'MAP'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    assert_equal 1, @handler.process_variants_from_report(@genotype, mutyh_record).size
  end

  test 'process_multiple_variants_single_gene' do
    multiple_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the PMS2 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the PMS2 gene.'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('Found MLH1 for list ["MLH1", "MSH2", "MSH6", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('Found MSH2 for list ["MLH1", "MSH2", "MSH6", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('Found MSH6 for list ["MLH1", "MSH2", "MSH6", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('Found EPCAM for list ["MLH1", "MSH2", "MSH6", "EPCAM"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    assert_equal 6, @handler.process_variants_from_report(@genotype, multiple_cdna_record).size
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
    { 'patient id' => 'Patient ID',
      sex:  'M',
      servicereportidentifier: 'Service Report Identifier',
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
      ref_fac: 'Ref FAC',
      city: 'CITY',
      name: 'NAME',
      providercode: 'Provider Code',
      'hospital address' => 'Hospital Address',
      'hospital city' => 'Hospital City',
      'hospital name' => 'Hospital Name',
      'hospital postcode' => 'Hospital Postcode',
      consultantcode: 'Consultant Code',
      'clinician surname' => 'M',
      'clinician first name' => 'Clinician name',
      'clinician role' => 'Clinician Role',
      specialty: 'Genetics',
      department: 'CLINICAL GENETICS'}.to_json
  end
end