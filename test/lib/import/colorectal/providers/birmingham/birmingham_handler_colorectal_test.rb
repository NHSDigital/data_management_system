require 'test_helper'

class BirminghamHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Birmingham::BirminghamHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestscope' do
    @handler.process_genetictestscope(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    @record.raw_fields['moleculartestingtype'] = 'RNA studies'
    @handler.process_genetictestscope(@genotype, @record)
    assert_equal 'Unable to assign Colorectal Lynch or MMR genetictestscope', @genotype.attribute_map['genetictestscope']
  end

  test 'process_multiple_tests_from_fullscreen' do
    @handler.process_genetictestscope(@genotype, @record)
    processor = variant_processor_for(@record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 3, genocolorectals.size
    assert_equal 2804, genocolorectals[0].attribute_map['gene']
    assert_equal 1432, genocolorectals[1].attribute_map['gene']
    assert_equal 2808, genocolorectals[2].attribute_map['gene']
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_equal 1, genocolorectals[1].attribute_map['teststatus']
    assert_equal 2, genocolorectals[2].attribute_map['teststatus']
    assert_equal 'Full screen Colorectal Lynch or MMR', genocolorectals[0].attribute_map['genetictestscope']
  end

  test 'process_mutation_from_fullscreen' do
    processor = variant_processor_for(@record)
    assert_equal 'p.Lys145Asn', processor.process_variants_from_report[2].attribute_map['proteinimpact']
  end

  test 'negative_tests_from_fullscreen' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['overall2'] = 'N'
    processor = variant_processor_for(negative_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 3, genocolorectals.size
    assert_equal 1, genocolorectals[2].attribute_map['teststatus']
  end

  test 'process_tests_from_empty_teststatus' do
    empty_teststatus_record = build_raw_record('pseudo_id1' => 'bob')
    empty_teststatus_record.raw_fields['teststatus'] = 'Cabbage'
    empty_teststatus_record.raw_fields['report'] = 'A mutation in exon 13 of the APC gene, a C to T transition at codon 554, has previously been reported in the Oxford DNA lab- oratory in this patient family. This mutation is detectable by direct PCR/DGGE analysis of exon 13.'
    empty_teststatus_record.raw_fields['indication'] = 'FAP'
    processor = variant_processor_for(empty_teststatus_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 1, genocolorectals.size
    assert_equal 358, genocolorectals[0].attribute_map['gene']
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
  end

  test 'process_chromosomevariants_from_record' do
    chromovariants_record = build_raw_record('pseudo_id1' => 'bob')
    chromovariants_record.raw_fields['teststatus'] = 'Frameshift mutation in exon 15 of hMSH2 plus missense mutation in exon 1 of hMLH1 identified'
    processor = variant_processor_for(chromovariants_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 4, genocolorectals.size
    assert_equal 10, genocolorectals[3].attribute_map['sequencevarianttype']
    assert_equal 2, genocolorectals[3].attribute_map['teststatus']
    assert_equal 2744, genocolorectals[3].attribute_map['gene']
    assert_equal 10, genocolorectals[2].attribute_map['sequencevarianttype']
    assert_equal 2, genocolorectals[2].attribute_map['teststatus']
    assert_equal 2804, genocolorectals[2].attribute_map['gene']
  end

  test 'process_mutyh_specific_single_cdna_variants' do
    mutyh_record = build_raw_record('pseudo_id1' => 'bob')
    mutyh_record.raw_fields['teststatus'] = 'Homozygous for the MYH gene mutation c.527A>G, p.Tyr176Cys.'
    mutyh_record.raw_fields['indication'] = 'MAP'
    processor = variant_processor_for(mutyh_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 1, genocolorectals.size
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
    assert_equal 'p.Tyr176Cys', genocolorectals[0].attribute_map['proteinimpact']
    assert_equal 'c.527A>G', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 2850, genocolorectals[0].attribute_map['gene']
  end

  test 'process_multiple_variants_single_gene' do
    multiple_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the PMS2 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the PMS2 gene.'
    processor = variant_processor_for(multiple_cdna_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 5, genocolorectals.size
    assert_equal 'c.251-20T>G', genocolorectals[4].attribute_map['codingdnasequencechange']
    assert_equal 2, genocolorectals[4].attribute_map['teststatus']
    assert_equal 3394, genocolorectals[4].attribute_map['gene']

    multiple_cdna_multiple_genes_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_multiple_genes_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the PMS2 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the MSH2 gene.'

    processor = variant_processor_for(multiple_cdna_multiple_genes_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 4, genocolorectals.size
    assert_equal 'p.Arg563Leu', genocolorectals[2].attribute_map['proteinimpact']
    assert_equal 'c.1688G>T', genocolorectals[2].attribute_map['codingdnasequencechange']
    assert_equal 2, genocolorectals[2].attribute_map['teststatus']
    assert_equal 3394, genocolorectals[2].attribute_map['gene']
    assert_nil genocolorectals[3].attribute_map['proteinimpact']
    assert_equal 'c.251-20T>G', genocolorectals[3].attribute_map['codingdnasequencechange']
    assert_equal 2, genocolorectals[3].attribute_map['teststatus']
    assert_equal 2804, genocolorectals[3].attribute_map['gene']
  end

  test 'process_chromosomic_variant_empty_teststatus' do
    empty_teststatus_chromovariant_record = build_raw_record('pseudo_id1' => 'bob')
    empty_teststatus_chromovariant_record.raw_fields['teststatus'] = 'Cabbage'
    empty_teststatus_chromovariant_record.raw_fields['report'] = 'The protein truncation test (PTT) detects the presence of chain-terminating mutations in the APC gene. A truncation has previously been identified in this patient family in the region of exon 15E to 15J.'
    empty_teststatus_chromovariant_record.raw_fields['indication'] = 'FAP'
    processor = variant_processor_for(empty_teststatus_chromovariant_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 1, genocolorectals.size
    assert_equal 358, genocolorectals[0].attribute_map['gene']
    assert_equal 10, genocolorectals[0].attribute_map['sequencevarianttype']
  end

  test 'process_variants_from_report_new_format' do
    pathogenic_record = build_raw_record('pseudo_id1' => 'bob')
    pathogenic_record.raw_fields['indication'] = 'PHTS'
    pathogenic_record.raw_fields['overall2'] = 'Pathogenic'
    pathogenic_record.raw_fields['teststatus'] = 'The previously reported heterozygous splice site variant c.802-1G>C in the PTEN gene is now considered likely pathogenic.'
    processor = variant_processor_for(pathogenic_record)
    genocolorectals = processor.process_variants_from_report
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
    assert_nil genocolorectals[0].attribute_map['proteinimpact']
    assert_equal 'c.802-1G>C', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 62, genocolorectals[0].attribute_map['gene']

    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['indication'] = 'PHTS'
    normal_record.raw_fields['overall2'] = 'Normal'
    normal_record.raw_fields['teststatus'] = 'Molecular analysis shows no evidence of the familial pathogenic variant in the PTEN gene.'
    processor = variant_processor_for(normal_record)
    genocolorectals2 = processor.process_variants_from_report
    assert_equal 1, genocolorectals2[0].attribute_map['teststatus']

    uv_record = build_raw_record('pseudo_id1' => 'bob')
    uv_record.raw_fields['indication'] = 'PHTS'
    uv_record.raw_fields['overall2'] = 'UV'
    uv_record.raw_fields['teststatus'] = 'Heterozygous inframe deletion variant of uncertain significance c.69_74del p.(Asp24_Leu25del) detected in the PTEN gene'
    processor = variant_processor_for(uv_record)
    genocolorectals3 =  processor.process_variants_from_report
    assert_equal 2, genocolorectals3[0].attribute_map['teststatus']
    assert_equal 3, genocolorectals3[0].attribute_map['variantpathclass']
    assert_equal 'c.69_74delp', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 62, genocolorectals[0].attribute_map['gene']
  end

  private

  def variant_processor_for(record)
    Import::Colorectal::Providers::Birmingham::VariantProcessor.new(@genotype, record, @logger)
  end

  def clinical_json
    { sex: '1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-10-17T00:00:00.000+01:00',
      authoriseddate: '2020-03-14T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2019-10-17T00:00:00.000+01:00',
      moleculartestingtype: '1',
      specimentype: '12',
      report: 'Next Generation Sequencing of coding regions in MSH2 (NM_000251.2) and MSH6 (NM_000179.2) (Illumina TruSight Hereditary Cancer Panel). WMRGL universal bioinformatics pipeline v0.5.2 (minimum sequencing depth 20x within exons and +/-5bp, calls with an allele frequency below 15% filtered out). Sanger sequencing as required. MLPA analysis of all MSH2 and MSH6 exons to detect whole exon deletions/duplications. MRC-Holland kits P003-D1 and P072-D1. MLPA also detects a recurrent 10MB inversion in MSH2 and 3’ deletions of EPCAM (NM_002354.3). These testing methods may not detect mosaic variants. Sequence nomenclature using HGVS guidelines. Variants classified according to ACGS Best Practice Guidelines 2020. DNA has been stored.',
      age: '999' }.to_json
  end

  def rawtext_clinical_json
    { 'patient id' => 'Patient ID',
      sex: 'M',
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
      department: 'CLINICAL GENETICS' }.to_json
  end
end
