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
    @handler.process_genetictestscope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    processor = variant_processor_for(@record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
  end

  test 'process_mutation_from_fullscreen' do
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(@record)
    genotypes = processor.process_variants_from_report
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'p.Thr1256Argfsx', genotypes[1].attribute_map['proteinimpact']
  end

  test 'negative_tests_from_fullscreen' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['overall2'] = 'N'
    @handler.process_genetictestscope(@genotype, negative_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    processor = variant_processor_for(negative_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
  end

  test 'process_chromosomevariants_from_record' do
    chromovariants_record = build_raw_record('pseudo_id1' => 'bob')
    chromovariants_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of a deletion (exon 16) in the BRCA1 gene'
    chromovariants_record.raw_fields['report'] = 'DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect deletions and duplications in the BRCA1 and BRCA2 genes.  Long range PCR has also been used to amplify across the deletion to confirm the MLPA result.'
    chromovariants_record.mapped_fields['report'] = 'DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect deletions and duplications in the BRCA1 and BRCA2 genes.  Long range PCR has also been used to amplify across the deletion to confirm the MLPA result.'
    @handler.process_genetictestscope(@genotype, chromovariants_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    processor = variant_processor_for(chromovariants_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal '16', genotypes[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_multiple_variants_single_gene' do
    multiple_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the BRCA2 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the BRCA2 gene.'
    @handler.process_genetictestscope(@genotype, multiple_cdna_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    processor = variant_processor_for(multiple_cdna_record)
    genotypes = processor.process_variants_from_report
    assert_equal 3, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.1688G>T', genotypes[1].attribute_map['codingdnasequencechange']
    assert_nil genotypes[1].attribute_map['proteinimpact']
    assert_equal 8, genotypes[2].attribute_map['gene']
    assert_equal 2, genotypes[2].attribute_map['teststatus']
    assert_equal 'c.251-20T>G', genotypes[2].attribute_map['codingdnasequencechange']
    assert_nil genotypes[2].attribute_map['proteinimpact']

    multiple_cdna_multiple_genes_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_cdna_multiple_genes_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T; p.Arg563Leu) identified in exon 11 of the BRCA1 gene and a heterozygous intronic variant (c.251-20T>G) in intron 4 of the BRCA2 gene.'
    @handler.process_genetictestscope(@genotype, multiple_cdna_multiple_genes_record)
    assert_equal @genotype.attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(multiple_cdna_multiple_genes_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.1688G>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.251-20T>G', genotypes[1].attribute_map['codingdnasequencechange']
    assert_nil genotypes[1].attribute_map['proteinimpact']
  end

  test 'process_result_without_brca_genes' do
    malformed_gene_record = build_raw_record('pseudo_id1' => 'bob')
    malformed_gene_record.raw_fields['teststatus'] = 'Molecular analysis shows 3875delGTCT mutation in BRCA 1.'
    malformed_gene_record.raw_fields['report'] = "DNA from this patient has been tested for BRCA1 and BRCA2 mutations by the protein truncation test (for exon 11 of BRCA1 and exons 10 and 11 of BRCA2) and by multiplex heteroduplex analysis (for exons 2, 11 5', 11 3' and 20 of BRCA1)."
    processor = variant_processor_for(malformed_gene_record)
    @handler.process_genetictestscope(@genotype, malformed_gene_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal genotypes[0].attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    assert_equal genotypes[1].attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.3875del', genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_noevidence_records' do
    noevidence_record = build_raw_record('pseudo_id1' => 'bob')
    noevidence_record.raw_fields['teststatus'] = 'No evidence of a pathogenic variant in the ATM, BRCA2, BRIP1, CHEK2, MLH1, MSH2, MSH6, \tNBN, PALB2, PTEN, RAD51C, RAD51D, STK11 or TP53 genes. \nHeterozygous missense variant (c.5481G>A; p.Met1827Ile) identified in exon 24 of the BRCA1 gene.'
    noevidence_record.raw_fields['report'] = 'The Illumina MiSeq platform has been used to sequence coding regions of a panel of 15 breast/ovarian cancer susceptibility genes: ATM  (NM_000051.3), BRCA1 (NM_007294.3), BRCA2 (NM_000059.3), BRIP1 (NM_032043.2), CHEK2 (NM_007194.3), MLH1 (NM_000249.3), MSH2  (NM_000251.2), MSH6 (NM_000179.2), NBN (NM_002485.4), PALB2 (NM_024675.3), PTEN (NM_000314.4), RAD51C (NM_058216.1), RAD51D  (NM_002878.3), STK11 (NM_000455.4) and TP53 (NM_000546.5) captured by the TruSight Cancer Panel target enrichment system (v1, Illumina). 100% of the target region of BRCA1,  BRCA2 and PALB2  has been covered either to a minimum depth of 25X by NGS or by Sanger sequencing. Coverage of other genes is available on request.  Variants of unknown clinical significance in genes other than BRCA1, BRCA2 and PALB2 have not been confirmed by Sanger sequencing or included within this  report. DNA has been stored.'
    processor = variant_processor_for(noevidence_record)
    @handler.process_genetictestscope(@genotype, noevidence_record)
    genotypes = processor.process_variants_from_report
    assert_equal 15, genotypes.size
    assert_equal genotypes[0].attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    assert_equal genotypes[1].attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    assert_equal 451, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 7, genotypes[14].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 2, genotypes[14].attribute_map['teststatus']
    assert_equal 'c.5481G>A', genotypes[14].attribute_map['codingdnasequencechange']
    assert_equal 'p.Met1827Ile', genotypes[14].attribute_map['proteinimpact']
    assert_equal '24', genotypes[14].attribute_map['exonintroncodonnumber']
  end

  test 'process_testresult_single_cdna_variant' do
    cdna_variants_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_variants_record.raw_fields['teststatus'] = 'Molecular analysis shows 4654G>T (S1512I)  mutation in BRCA1'
    cdna_variants_record.raw_fields['report'] = "DNA from this patient has been tested for BRCA1 and BRCA2 mutations by the protein truncation test (for exon 11 of BRCA1 and exons 10 and 11 of BRCA2) and by multiplex heteroduplex analysis (for exons 2, 11 5', 11 3' and 20 of BRCA1)."
    processor = variant_processor_for(cdna_variants_record)
    @handler.process_genetictestscope(@genotype, cdna_variants_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.4654G>T', genotypes[1].attribute_map['codingdnasequencechange']
    assert_nil genotypes[1].attribute_map['proteinimpact']
  end

  test 'process_testresult_multiple_cdna_variant' do
    multi_cdna_variants_record = build_raw_record('pseudo_id1' => 'bob')
    multi_cdna_variants_record.raw_fields['teststatus'] = 'Molecular analysis shows 5075G>A (M1652I) sequence variant in BRCA1 and 8410G>A (V2728I) sequence variant in BRCA2'
    multi_cdna_variants_record.raw_fields['report'] = 'DNA from this patient has been tested for BRCA1 and BRCA2 mutations by a combination of the protein truncation test, multiplex heteroduplex analysis, dHPLC analysis and the exon 13 duplication test collectively covering the entire coding region of both genes.'
    processor = variant_processor_for(multi_cdna_variants_record)
    @handler.process_genetictestscope(@genotype, multi_cdna_variants_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.5075G>A', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.8410G>A', genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_known_as_variant' do
    knownas_cdna_variant_record = build_raw_record('pseudo_id1' => 'bob')
    knownas_cdna_variant_record.raw_fields['teststatus'] = 'Molecular analysis shows c.5385dupC (p.Gln1756ProfsX74) mutation (previously known as c.5382insC) in exon 20 of the BRCA1 gene.'
    knownas_cdna_variant_record.raw_fields['report'] = 'DNA from this patient has undergone fluorescent cycle sequence analysis for  BRCA1 exon 20.  Mutation nomenclature according to GenBank accession number U14680 (BRCA1), assuming that the A of the ATG start codon (codon 1) is nucleotide number 120, and as recommended by the HGVS website.'
    processor = variant_processor_for(knownas_cdna_variant_record)
    @handler.process_genetictestscope(@genotype, knownas_cdna_variant_record)
    genotypes = processor.process_variants_from_report
    assert_equal 1, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.5385dupC', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Gln1756Profsx', genotypes[0].attribute_map['proteinimpact']
  end

  test 'process_single_variant_multigene' do
    single_variant_multigene_record = build_raw_record('pseudo_id1' => 'bob')
    single_variant_multigene_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of a deletion (exons 1 to 17) in the BRCA1 gene.  Missense mutation also identified in BRCA2 exon 15 (c.7727G>C, p.Arg2500Thr).'
    single_variant_multigene_record.raw_fields['report'] = 'Automated sequencing analysis has been used to screen all coding exons of the BRCA1 and BRCA2 genes unless otherwise stated. Multiplex ligation-dependent probe amplification (MLPA) analysis of all exons of BRCA1 and all exons except 5 and 23 of BRCA2 has been performed to detect deletions and duplications. GenBank accession numbers used: U14680 (BRCA1, A of the initiation codon is nucleotide 120) & U43746 (BRCA2, A of the initiation codon is nucleotide 229). DNA extracted from this sample has been stored.'
    processor = variant_processor_for(single_variant_multigene_record)
    @handler.process_genetictestscope(@genotype, single_variant_multigene_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal '1-17', genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 'c.7727G>C', genotypes[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg2500Thr', genotypes[1].attribute_map['proteinimpact']
    assert_equal '15', genotypes[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_chr_variant' do
    chr_variant_record = build_raw_record('pseudo_id1' => 'bob')
    chr_variant_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of a deletion (exons 1 to 2) in the BRCA2 gene.'
    chr_variant_record.raw_fields['report'] = "DNA from this patient has undergone Multiplex Ligation-dependent Probe Amplification (MLPA) to detect deletions and duplications in the BRCA1 and BRCA2 genes.\nSee previous reports dated 28/01/00 and 15/02/01 (D94.7983)."
    processor = variant_processor_for(chr_variant_record)
    @handler.process_genetictestscope(@genotype, chr_variant_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal '1-2', genotypes[1].attribute_map['exonintroncodonnumber']
    assert_equal 3, genotypes[1].attribute_map['sequencevarianttype']
  end

  test 'process_chr_malformed_variants' do
    chr_malformed_variant_record = build_raw_record('pseudo_id1' => 'bob')
    chr_malformed_variant_record.raw_fields['teststatus'] = 'Splice-site mutation (c.5525+1 G>A) identified at the splice donor site of exon 22 of the BRCA1 gene'
    chr_malformed_variant_record.raw_fields['report'] = 'Automated sequencing analysis has been used to screen all coding exons of the BRCA1 and BRCA2 genes unless otherwise stated. Multiplex Ligation-dependent Probe Amplification (MLPA) analysis of all exons of BRCA1 and all exons except 5, 6, 23 and 26 of BRCA2 has been performed to detect deletions and duplications. GenBank accession numbers used: U14680 (BRCA1, A of the initiation codon is nucleotide 120) & U43746 (BRCA2, A of the initiation codon is nucleotide 229).'
    processor = variant_processor_for(chr_malformed_variant_record)
    @handler.process_genetictestscope(@genotype, chr_malformed_variant_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal '22', genotypes[1].attribute_map['exonintroncodonnumber']
    assert_equal 'c.', genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_positive_malformed_variants_targeted' do
    positive_malformed_record = build_raw_record('pseudo_id1' => 'bob')
    positive_malformed_record.raw_fields['teststatus'] = 'Both BRCA1 and BRCA2 mutations present'
    positive_malformed_record.raw_fields['report'] = 'PCR fragments localised to the coding regions of exon 11 of the familial breast-/ovarian cancer genes, BRCA1 and BRCA2, have undergone molecular analysis to detect mutations previously identified in this family.'
    processor = variant_processor_for(positive_malformed_record)
    @handler.process_genetictestscope(@genotype, positive_malformed_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal genotypes[0].attribute_map['genetictestscope'], 'Targeted BRCA mutation test'
    assert_equal genotypes[1].attribute_map['genetictestscope'], 'Targeted BRCA mutation test'
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'c.', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.', genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_empty_testreport_results' do
    empty_testreport_result_record = build_raw_record('pseudo_id1' => 'bob')
    empty_testreport_result_record.raw_fields['teststatus'] = 'Molecular analysis shows presence of the familial mutation in the BRCA2 gene.'
    empty_testreport_result_record.raw_fields['report'] = ''
    processor = variant_processor_for(empty_testreport_result_record)
    @handler.process_genetictestscope(@genotype, empty_testreport_result_record)
    genotypes = processor.process_variants_from_report
    assert_equal 1, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.', genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_negative_records' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['overall2'] = 'N'
    negative_record.raw_fields['teststatus'] = 'Molecular analysis has shown no evidence of the familial pathogenic mutation in the BRCA2 gene.'
    negative_record.raw_fields['report'] = 'Exon 20 of the BRCA2 gene has been sequenced to detect a pathogenic mutation previously identified in this family. Sequence nomenclature according to HGVS guidelines using GenBank accession number U43746.1 (BRCA2). Non-amplification of an allele due to possible polymorphisms within the primer binding site cannot be fully excluded. DNA has been stored.'
    processor = variant_processor_for(negative_record)
    @handler.process_genetictestscope(@genotype, negative_record)
    genotypes = processor.process_variants_from_report
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_multigene_single_protein' do
    multigene_single_protein_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_single_protein_record.raw_fields['teststatus'] = 'Heterozygous missense variant (c.1688G>T) identified in exon 11 of the BRCA1 gene and a heterozygous intronic variant (c.251-20T>G; p.Arg563Leu) in intron 4 of the BRCA2 gene.'
    @handler.process_genetictestscope(@genotype, multigene_single_protein_record)
    assert_equal @genotype.attribute_map['genetictestscope'], 'Full screen BRCA1 and BRCA2'
    processor = variant_processor_for(multigene_single_protein_record)
    genotypes = processor.process_variants_from_report
    assert_equal 2, genotypes.size
    assert_equal 'c.1688G>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.251-20T>G', genotypes[1].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    # we do not capture proteins when cdnas are more than proteins to avoid wrong assosciation
    assert_nil genotypes[1].attribute_map['proteinimpact']
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
