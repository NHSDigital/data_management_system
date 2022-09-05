require 'test_helper'

class SheffieldHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Sheffield::SheffieldHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'add_test_scope_from_geno_karyo' do
    @logger.expects(:debug).with('ADDED TARGETED TEST for: BRCA cDNA analysis')
    @handler.add_test_scope_from_geno_karyo(@genotype, @record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    fullscreen_record = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_record.raw_fields['karyotypingmethod'] = 'BRCA1 and 2 gene sequencing'
    @logger.expects(:debug).with('ADDED FULL_SCREEN TEST for: BRCA1 and 2 gene sequencing')
    @handler.add_test_scope_from_geno_karyo(@genotype, fullscreen_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    nogenetictest_record = build_raw_record('pseudo_id1' => 'bob')
    nogenetictest_record.raw_fields['genetictestscope'] = 'R208 :: Inherited breast cancer and ovarian cancer'
    nogenetictest_record.raw_fields['karyotypingmethod'] = 'R208.1 :: NGS in Leeds'
    @logger.expects(:debug).with('ADDED FULL_SCREEN TEST for: R208.1 :: NGS in Leeds')
    @handler.add_test_scope_from_geno_karyo(@genotype, nogenetictest_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'add_test_type' do
    @handler.add_test_type(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
  end

  test 'process_variants_from_record' do
    @handler.add_test_scope_from_geno_karyo(@genotype, @record)
    genotypes = @handler.process_variants_from_record(@genotype, @record)
    assert_equal 1, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.520C>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal 8, genotypes[0].attribute_map['gene']
  end

  test 'mlpa_fail_full_screen' do
    mlpa_fail_fs_record = build_raw_record('pseudo_id1' => 'bob')
    mlpa_fail_fs_record.raw_fields['genetictestscope'] = 'Breast & Ovarian cancer panel'
    mlpa_fail_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 & BRCA2 only'
    mlpa_fail_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected - BRCA2 MLPA failed'
    @handler.add_test_scope_from_geno_karyo(@genotype, mlpa_fail_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, mlpa_fail_fs_record)
    assert_equal 2, genotypes.size
    # MLPA failed gene
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    # MLPA method
    assert_equal 15, genotypes[0].attribute_map['karyotypingmethod']
    # Rest negative genes
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
  end

  test 'normal_full_screen' do
    normal_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normal_fs_record.raw_fields['genetictestscope'] = 'Breast & Ovarian cancer panel'
    normal_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 and BRCA2'
    normal_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected'
    @handler.add_test_scope_from_geno_karyo(@genotype, normal_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, normal_fs_record)
    assert_equal 2, genotypes.size
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil  genotypes[0].attribute_map['proteinimpact']
    assert_nil  genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'failed_full_screen' do
    fail_fs_record = build_raw_record('pseudo_id1' => 'bob')
    fail_fs_record.raw_fields['genetictestscope'] = 'Breast & Ovarian cancer panel'
    fail_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 and BRCA2'
    fail_fs_record.raw_fields['genotype'] = 'FAIL'
    @handler.add_test_scope_from_geno_karyo(@genotype, fail_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, fail_fs_record)
    assert_equal 2, genotypes.size
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 9, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
  end

  test 'multiple_variant_fs_record' do
    multiple_variant_fs_record = build_raw_record('pseudo_id1' => 'bob')
    multiple_variant_fs_record.raw_fields['genetictestscope'] = 'R208 :: BRCA1 and BRCA2 testing at high familial risk'
    multiple_variant_fs_record.raw_fields['karyotypingmethod'] = 'R208.1 :: Unknown mutation(s) by Single gene sequencing'
    multiple_variant_fs_record.raw_fields['genotype'] = 'BRCA2: c.9175A>G:p.Lys3059Glu PALB2: c.1250C>A:p.Ser417Tyr - see comments'
    @handler.add_test_scope_from_geno_karyo(@genotype, multiple_variant_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, multiple_variant_fs_record)
    assert_equal %w[BRCA1 BRCA2 PALB2], @handler.instance_variable_get('@genes_set')
    assert_equal 3, genotypes.size

    # positive genes
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'p.Lys3059Glu', genotypes[0].attribute_map['proteinimpact']
    assert_equal 'c.9175A>G', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 8, genotypes[0].attribute_map['gene']

    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 'p.Ser417Tyr', genotypes[1].attribute_map['proteinimpact']
    assert_equal 'c.1250C>A', genotypes[1].attribute_map['codingdnasequencechange']
    assert_equal 3186, genotypes[1].attribute_map['gene']

    # negative gene
    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_nil  genotypes[2].attribute_map['proteinimpact']
    assert_nil  genotypes[2].attribute_map['codingdnasequencechange']
    assert_equal 7, genotypes[2].attribute_map['gene']
  end

  test 'single_variant_fs_record' do
    single_variant_fs_record = build_raw_record('pseudo_id1' => 'bob')
    single_variant_fs_record.raw_fields['genetictestscope'] = 'Breast & Ovarian cancer panel'
    single_variant_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 & BRCA2 only'
    single_variant_fs_record.raw_fields['genotype'] = 'BRCA1: c.[4986+4_4986+13del];[=]'
    @handler.add_test_scope_from_geno_karyo(@genotype, single_variant_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, single_variant_fs_record)
    assert_equal %w[BRCA1 BRCA2], @handler.instance_variable_get('@genes_set')
    assert_equal 2, genotypes.size

    # positive genes
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal 'c.4986+4_4986+13del', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 7, genotypes[0].attribute_map['gene']

    # negative gene
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_nil  genotypes[1].attribute_map['proteinimpact']
    assert_nil  genotypes[1].attribute_map['codingdnasequencechange']
    assert_equal 8, genotypes[1].attribute_map['gene']
  end

  test 'only_protein_fs_record' do
    protein_fs_record = build_raw_record('pseudo_id1' => 'bob')
    protein_fs_record.raw_fields['genetictestscope'] = 'BRCA1 and 2 gene analysis'
    protein_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 and 2 gene sequencing'
    protein_fs_record.raw_fields['genotype'] = 'p.[(Leu1768fs)];[=]'
    @handler.add_test_scope_from_geno_karyo(@genotype, protein_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, protein_fs_record)
    assert_equal %w[BRCA1 BRCA2], @handler.instance_variable_get('@genes_set')
    assert_equal 2, genotypes.size
    assert_equal 4, genotypes[0].attribute_map['teststatus']
    assert_equal 4, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
  end

  test 'multi_genes_targeted' do
    multi_genes_tar_record = build_raw_record('pseudo_id1' => 'bob')
    multi_genes_tar_record.raw_fields['genetictestscope'] = 'R208 :: BRCA1 and BRCA2 testing at high familial risk'
    multi_genes_tar_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    multi_genes_tar_record.raw_fields['genotype'] = 'BRCA1: pathogenic heterozygous deletion involving exons 1 and 2 BRCA2: c.[7069_7070del];[7069_7070=], p.[(Leu2357fs)];[(Leu2357=)]'
    @handler.add_test_scope_from_geno_karyo(@genotype, multi_genes_tar_record)
    genotypes = @handler.process_variants_from_record(@genotype, multi_genes_tar_record)
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal '1and2', genotypes[0].attribute_map['exonintroncodonnumber']

    assert_equal 2, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 'c.7069_7070del', genotypes[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Leu2357fs', genotypes[1].attribute_map['proteinimpact']
  end

  test 'normal_targeted' do
    normal_tar_record = build_raw_record('pseudo_id1' => 'bob')
    normal_tar_record.raw_fields['genetictestscope'] = 'R206 :: Inherited breast cancer and ovarian cancer at high familial risk levels'
    normal_tar_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    normal_tar_record.raw_fields['genotype'] = 'Familal BRCA1 pathogenic mutation NOT detected - See Comment'
    @handler.add_test_scope_from_geno_karyo(@genotype, normal_tar_record)
    genotypes = @handler.process_variants_from_record(@genotype, normal_tar_record)

    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes.size
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['exonintroncodonnumber']
    assert_nil  genotypes[0].attribute_map['proteinimpact']
    assert_nil  genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'failed_targ' do
    fail_tar_record = build_raw_record('pseudo_id1' => 'bob')
    fail_tar_record.raw_fields['genetictestscope'] = 'BRCA1 and 2 gene analysis'
    fail_tar_record.raw_fields['karyotypingmethod'] = 'BRCA2 gene sequencing'
    fail_tar_record.raw_fields['genotype'] = 'BRCA2: sequencing failed'
    @handler.add_test_scope_from_geno_karyo(@genotype, fail_tar_record)
    genotypes = @handler.process_variants_from_record(@genotype, fail_tar_record)
    assert_equal 1, genotypes.size
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
  end

  test 'protein_targeted' do
    protein_tar_record = build_raw_record('pseudo_id1' => 'bob')
    protein_tar_record.raw_fields['genetictestscope'] = 'BRCA1 and 2 gene analysis'
    protein_tar_record.raw_fields['karyotypingmethod'] = 'BRCA1 gene sequencing'
    protein_tar_record.raw_fields['genotype'] = 'p.[(Leu392fs)];[=]'
    @handler.add_test_scope_from_geno_karyo(@genotype, protein_tar_record)
    genotypes = @handler.process_variants_from_record(@genotype, protein_tar_record)
    assert_equal 1, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 'p.Leu392fs', genotypes[0].attribute_map['proteinimpact']
    assert_equal 'c.', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
  end

  test 'detected_but_no_mutation_targeted' do
    detected_tar_record = build_raw_record('pseudo_id1' => 'bob')
    detected_tar_record.raw_fields['genetictestscope'] = 'BRCA1 and 2 gene analysis'
    detected_tar_record.raw_fields['karyotypingmethod'] = 'BRCA1 gene sequencing'
    detected_tar_record.raw_fields['genotype'] = 'Familial mutation detected'
    @handler.add_test_scope_from_geno_karyo(@genotype, detected_tar_record)
    genotypes = @handler.process_variants_from_record(@genotype, detected_tar_record)
    assert_equal 1, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 'p.', genotypes[0].attribute_map['proteinimpact']
    assert_equal 'c.', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
  end

  test 'malformed_mutation_fs' do
    malformed_mutation_fs_record = build_raw_record('pseudo_id1' => 'bob')
    malformed_mutation_fs_record.raw_fields['genetictestscope'] = 'Breast & Ovarian cancer panel'
    malformed_mutation_fs_record.raw_fields['karyotypingmethod'] = 'BRCA1 & BRCA2 only'
    malformed_mutation_fs_record.raw_fields['genotype'] = 'BRCA2 c[8575del];[=]  p.[(Gln2859fs)];[(=)]'
    @handler.add_test_scope_from_geno_karyo(@genotype, malformed_mutation_fs_record)
    genotypes = @handler.process_variants_from_record(@genotype, malformed_mutation_fs_record)
    assert_equal 2, genotypes.size
    assert_equal 4, genotypes[0].attribute_map['teststatus']
    assert_equal 4, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['exonintroncodonnumber']
    assert_nil  genotypes[0].attribute_map['proteinimpact']
    assert_nil  genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
  end

  test 'mutation_but_no_gene_target' do
    mutation_no_gene_targ_record = build_raw_record('pseudo_id1' => 'bob')
    mutation_no_gene_targ_record.raw_fields['genetictestscope'] = 'R208 :: BRCA1 and BRCA2 testing at high familial risk'
    mutation_no_gene_targ_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    mutation_no_gene_targ_record.raw_fields['genotype'] = '[c.3607C>T];[3607=] p.[(Arg1203*)];[(Arg1203=)] Heterozygous result'
    @handler.add_test_scope_from_geno_karyo(@genotype, mutation_no_gene_targ_record)
    genotypes = @handler.process_variants_from_record(@genotype, mutation_no_gene_targ_record)
    assert_equal 1, genotypes.size
    assert_equal 4, genotypes[0].attribute_map['teststatus']
    assert_nil  genotypes[0].attribute_map['proteinimpact']
    assert_nil  genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['gene']
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
  end

  private

  def clinical_json
    { sex: '1',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      collecteddate: '2018-06-13T00:00:00.000+01:00',
      receiveddate: '2018-06-13T00:00:00.000+01:00',
      authoriseddate: '2018-07-04T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2018-06-13T00:00:00.000+01:00',
      genetictestscope: 'BRCA1 and 2 gene analysis',
      karyotypingmethod: 'BRCA cDNA analysis',
      specimentype: '5',
      genotype: 'BRCA2: c.[520C>T];[520=]  p.[(?)];[(=)]',
      age: 63 }.to_json
  end

  def rawtext_clinical_json
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
      genetictestscope: 'BRCA1 and 2 gene analysis',
      karyotypingmethod: 'BRCA cDNA analysis' }.to_json
  end
end
