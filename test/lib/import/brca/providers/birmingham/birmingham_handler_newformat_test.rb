require 'test_helper'

class BirminghamHandlerNewformatTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Birmingham::BirminghamHandlerNewformat.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestscope' do
    @handler.process_genetictestscope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'process_multiple_tests_from_fullscreen' do
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found BRCA2 for list ["BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(@record)
    assert_equal 2, processor.process_variants_from_report.size
  end

  test 'process_mutation_from_fullscreen' do
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found BRCA2 for list ["BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(@record)
    assert_equal 'p.Thr1256Argfsx', processor.process_variants_from_report[1].attribute_map['proteinimpact']
  end

  test 'negative_tests_from_fullscreen' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['overall2'] = 'N'
    @logger.expects(:debug).with('NORMAL TEST FOUND')
    @logger.expects(:debug).with('Found BRCA1 for list ["BRCA1", "BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('Found BRCA2 for list ["BRCA1", "BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(negative_record)
    assert_equal 2, processor.process_variants_from_report.size
  end

  test 'process_chromosomevariants_from_record' do
    chromovariants_record = build_raw_record('pseudo_id1' => 'bob')
    chromovariants_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of a deletion (exon 16) in the BRCA1 gene'
    chromovariants_record.raw_fields['report'] = 'DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect deletions and duplications in the BRCA1 and BRCA2 genes.  Long range PCR has also been used to amplify across the deletion to confirm the MLPA result.'
    chromovariants_record.mapped_fields['report'] = 'DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect deletions and duplications in the BRCA1 and BRCA2 genes.  Long range PCR has also been used to amplify across the deletion to confirm the MLPA result.'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found BRCA2 for list ["BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(chromovariants_record)
    assert_equal 2, processor.process_variants_from_report.size
  end

  test 'process_multiple_variants_single_gene' do
    multiple_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the BRCA2 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the BRCA2 gene.'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found BRCA1 for list ["BRCA1"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(multiple_cdna_record)
    assert_equal 3, processor.process_variants_from_report.size

    multiple_cdna_multiple_genes_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_multiple_genes_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the BRCA1 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the BRCA2 gene.'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(multiple_cdna_multiple_genes_record)
    assert_equal 2, processor.process_variants_from_report.size
  end

  test 'process_positive_malformed_variants' do
    malformed_record = build_raw_record('pseudo_id1' => 'bob')
    malformed_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of the familial mutation in the BRCA1 gene.'
    malformed_record.raw_fields['report'] = 'DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect a mutation previously identified in this family.\n\nMutation nomenclature according to GenBank accession number U14680 (BRCA1)/U43746 (BRCA2).'
    @logger.expects(:debug).with('ABNORMAL TEST')
    @logger.expects(:debug).with('Found BRCA2 for list ["BRCA2"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(malformed_record)
    assert_equal 3, processor.process_variants_from_report.size
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

  def variant_processor_for(record)
    Import::Brca::Providers::Birmingham::VariantProcessor.new(@genotype, record, @logger)
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2009-04-28T00:00:00.000+01:00',
      authoriseddate: '2009-06-12T00:00:00.000+01:00',
      servicereportidentifier: 'ServiceReportIdentifier',
      sortdate: '2009-04-28T00:00:00.000+01:00',
      moleculartestingtype: '1',
      specimentype: '5',
      report: 'Sequencing analysis has been used to screen coding exons of the BRCA1 and BRCA2 genes. Due to the identification of a pathogenic mutation the entire BRCA1 and BRCA2 coding sequences may not have been completely screened. Sequence nomenclature using HGVS guidelines. GenBank accession numbers: U14680.1 (BRCA1) and U43746.1 (BRCA2). MLPA analysis of all exons of BRCA1 and BRCA2 to detect whole exon deletions and duplications (MRC-Holland kits P002-B1 and P090-A1 respectively). DNA has been stored.',
      age: '999' }.to_json
  end

  def rawtext_clinical_json
    { 'patient id' => 'PatientID',
      sex: 'F',
      servicereportidentifier: 'ServiceReportIdentifier',
      reason: 'Diagnosis',
      moleculartestingtype: 'Diagnosis',
      reportresult: 'C40-BRCA HT Frameshift Pathogenic',
      authoriseddate: '2009-06-12 00:00:00',
      teststatus: 'Heterozygous frameshift mutation (c.3767_3768delCA; p.Thr1256ArgfsX10) identified in exon 11 of the BRCA1 gene.',
      overall2: 'P',
      'sarah class 3' => '#N/A',
      'sarah class 4' => '#N/A',
      'sarah class 5' => '#N/A',
      indication: 'BRCA',
      receiveddate: '2009-04-28 00:00:00',
      specimentype: 'Blood',
      report: 'Sequencing analysis has been used to screen coding exons of the BRCA1 and BRCA2 genes. Due to the identification of a pathogenic mutation the entire BRCA1 and BRCA2 coding sequences may not have been completely screened. Sequence nomenclature using HGVS guidelines. GenBank accession numbers: U14680.1 (BRCA1) and U43746.1 (BRCA2). MLPA analysis of all exons of BRCA1 and BRCA2 to detect whole exon deletions and duplications (MRC-Holland kits P002-B1 and P090-A1 respectively). DNA has been stored.',
      ref_fac: 'REF_FAC',
      city: 'City',
      name: 'Hospital',
      providercode: 'ProviderCode',
      'hospital address' => 'Hospital Address',
      'hospital city' => 'City',
      'hospital name' => 'Hospital Name',
      'hospital postcode' => 'PostCode',
      consultantcode: 'ConsultantCode',
      'clinician surname' => 'Surname',
      'clinician first name' => 'Name',
      'clinician role' => 'Role',
      specialty: 'Specialty',
      department: 'Department' }.to_json
  end
end
