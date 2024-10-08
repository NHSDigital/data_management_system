require 'test_helper'

class StGeorgeHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::StGeorge::StGeorgeHandlerColorectal.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'process_fields' do
    # test that nothing is added to record if SRI doesn't start with 'V'
    valid_sri_record = build_raw_record('pseudo_id1' => 'bob')
    valid_sri_record.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    valid_sri_record.raw_fields['servicereportidentifier'] = 'V123456'
    valid_sri_record.raw_fields['gene'] = 'ATM'
    genotypes = @handler.process_fields(valid_sri_record)
    assert_equal 'V123456', genotypes[0].attribute_map['servicereportidentifier']

    invalid_sri_record = build_raw_record('pseudo_id1' => 'bob')
    invalid_sri_record.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    invalid_sri_record.raw_fields['servicereportidentifier'] = 'W123456'
    valid_sri_record.raw_fields['gene'] = 'ATM'
    genotypes = @handler.process_fields(invalid_sri_record)
    assert_nil genotypes
  end

  test 'assign_test_type' do
    carrier_record1 = build_raw_record('pseudo_id1' => 'bob')
    carrier_record1.raw_fields['moleculartestingtype'] = 'Carrier testing for known familial mutation(s)'
    @handler.assign_test_type(@genotype, carrier_record1)
    assert_equal 3, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record4 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record4.raw_fields['moleculartestingtype'] = 'APC associated Polyposis'
    @handler.assign_test_type(@genotype, diagnostic_record4)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record5 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record5.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    @handler.assign_test_type(@genotype, diagnostic_record5)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    predictive_record1 = build_raw_record('pseudo_id1' => 'bob')
    predictive_record1.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    @handler.assign_test_type(@genotype, predictive_record1)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
  end

  test 'assign_test_scope' do
    testscope_no_testscope = build_raw_record('pseudo_id1' => 'bob')
    testscope_no_testscope.raw_fields['moleculartestingtype'] = 'no molecular testing type'
    @logger.expects(:error).with('ERROR - record with no genetic test scope, ask Fiona for new rules')
    @handler.assign_test_scope(@genotype, testscope_no_testscope)

    testscope_targeted_record1 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record1.raw_fields['moleculartestingtype'] = 'Carrier testing for known familial mutation(s)'
    @handler.assign_test_scope(@genotype, testscope_targeted_record1)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_targeted_record2 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record2.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    @handler.assign_test_scope(@genotype, testscope_targeted_record2)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_targeted_record3 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record3.raw_fields['moleculartestingtype'] = 'Family follow-up testing to aid variant interpretation'
    @handler.assign_test_scope(@genotype, testscope_targeted_record3)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_targeted_record4 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record4.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    @handler.assign_test_scope(@genotype, testscope_targeted_record4)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_fs_record1 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record1.raw_fields['moleculartestingtype'] = 'Inherited colorectal cancer (with or without polyposis)'
    @handler.assign_test_scope(@genotype, testscope_fs_record1)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_fs_record2 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record2.raw_fields['moleculartestingtype'] = 'Inherited MMR deficiency (Lynch syndrome)'
    @handler.assign_test_scope(@genotype, testscope_fs_record2)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    testscope_fs_record3 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record3.raw_fields['moleculartestingtype'] = 'Inherited polyposis - germline test'
    @handler.assign_test_scope(@genotype, testscope_fs_record3)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'process_genes' do
    # test where it is not a panel

    mhs6_typo = build_raw_record('pseudo_id1' => 'bob')
    mhs6_typo.raw_fields['gene'] = 'MHS2'
    mhs6_typo.raw_fields['gene (other)'] = 'unknown'
    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    genes_dict = @handler.process_genes(@genotype, mhs6_typo)
    assert_equal ({ 'gene' => %w[MSH2], 'gene (other)' => [] }), genes_dict

    targeted_crc = build_raw_record('pseudo_id1' => 'bob')
    targeted_crc.raw_fields['gene'] = 'MLH1'
    targeted_crc.raw_fields['gene (other)'] = 'MSH6'
    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    genes_dict = @handler.process_genes(@genotype, targeted_crc)
    assert_equal ({ 'gene' => %w[MLH1], 'gene (other)' => ['MSH6'] }), genes_dict

    fs_crc = build_raw_record('pseudo_id1' => 'bob')
    fs_crc.raw_fields['gene'] = ''
    fs_crc.raw_fields['gene (other)'] = 'MLH1, MSH2, MSH6, EPCAM'
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    genes_dict = @handler.process_genes(@genotype, fs_crc)
    assert_equal ({ 'gene' => %w[], 'gene (other)' => %w[MLH1 MSH2 MSH6 EPCAM] }), genes_dict
  end

  test 'process_test_panels' do
    r209 = build_raw_record('pseudo_id1' => 'bob')
    r209.raw_fields['test/panel'] = 'R209'
    genes = @handler.process_test_panels(r209, [], 'test/panel')
    assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11], genes

    lynch = build_raw_record('pseudo_id1' => 'bob')
    lynch.raw_fields['test/panel'] = 'Lynch (R210)'
    genes = @handler.process_test_panels(lynch, [], 'test/panel')
    assert_equal %w[EPCAM MLH1 MSH2 MSH6 PMS2], genes

    r414 = build_raw_record('pseudo_id1' => 'bob')
    r414.raw_fields['test/panel'] = 'R414'
    genes = @handler.process_test_panels(r414, [], 'test/panel')
    assert_equal %w[APC], genes
  end

  test 'process_r211' do
    r211_before = build_raw_record('pseudo_id1' => 'bob')
    r211_before.raw_fields['test/panel'] = 'R211'
    r211_before.raw_fields['authoriseddate'] = '17/07/2022'
    genes = @handler.process_r211(r211_before)
    assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11], genes

    r211_after = build_raw_record('pseudo_id1' => 'bob')
    r211_after.raw_fields['test/panel'] = 'R211'
    r211_after.raw_fields['authoriseddate'] = '18/07/2022'
    genes = @handler.process_r211(r211_after)
    assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11 GREM1 RNF43], genes
  end

  test 'handle_test_status' do
    fs_gene_column = build_raw_record('pseudo_id1' => 'bob')
    fs_gene_column.raw_fields['gene'] = 'MSH2'
    fs_gene_column.raw_fields['gene (other)'] = 'unknown'
    fs_gene_column.raw_fields['variant dna'] = 'unknown'
    fs_gene_column.raw_fields['variant protein'] = 'unknown'
    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    genotypes = @handler.handle_test_status(fs_gene_column, @genotype, { 'gene' => ['MSH2'], 'gene (other)' => [], 'variant dna' => [], 'variant protein' => [], 'test/panel' => [] })
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes.length

    fs_geneother_column = build_raw_record('pseudo_id1' => 'bob')
    fs_geneother_column.raw_fields['gene'] = 'MSH2'
    fs_geneother_column.raw_fields['gene (other)'] = 'APC'
    fs_gene_column.raw_fields['variant dna'] = 'unknown'
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    genotypes = @handler.handle_test_status(fs_geneother_column, @genotype, { 'gene' => ['MSH2'], 'gene (other)' => ['APC'], 'variant dna' => [], 'test/panel' => [] })
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes.length
  end

  test 'duplicate_genotype' do
    fs_gene_column = build_raw_record('pseudo_id1' => 'bob')
    fs_gene_column.raw_fields['gene'] = 'MSH2'
    fs_gene_column.raw_fields['gene (other)'] = 'unknown'
    fs_gene_column.raw_fields['variant dna'] = 'unknown'
    fs_gene_column.raw_fields['variant protein'] = 'unknown'
    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    genotypes = @handler.duplicate_genotype(['gene', 'gene (other)'], @genotype, { 'gene' => ['MSH2'], 'gene (other)' => [], 'variant dna' => [], 'variant protein' => [], 'test/panel' => [] }, fs_gene_column)
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes.length

    fs_geneother_column = build_raw_record('pseudo_id1' => 'bob')
    fs_geneother_column.raw_fields['gene'] = 'MSH2'
    fs_geneother_column.raw_fields['gene (other)'] = 'APC'
    fs_gene_column.raw_fields['variant dna'] = 'unknown'
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    genotypes = @handler.duplicate_genotype(['gene', 'gene (other)'], @genotype, { 'gene' => ['MSH2'], 'gene (other)' => ['APC'], 'variant dna' => [], 'test/panel' => [] }, fs_gene_column)
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes.length
  end

  test 'assign_test_status_full_screen' do
    fs_variant_dna_fail = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_fail.raw_fields['gene'] = 'APC'
    fs_variant_dna_fail.raw_fields['variant dna'] = 'Fail'
    @handler.assign_test_status_fullscreen(fs_variant_dna_fail, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }, 'gene')
    assert_equal 9, @genotype.attribute_map['teststatus']

    fs_variant_dna_n = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_n.raw_fields['gene'] = 'APC'
    fs_variant_dna_n.raw_fields['variant dna'] = 'N'
    @handler.assign_test_status_fullscreen(fs_variant_dna_n, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }, 'gene')
    assert_equal 1, @genotype.attribute_map['teststatus']

    fs_variant_dna_c = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_c.raw_fields['gene'] = 'APC'
    fs_variant_dna_c.raw_fields['variant dna'] = 'c.3920T>A'
    @handler.assign_test_status_fullscreen(fs_variant_dna_c, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_dna_gene_null = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_gene_null.raw_fields['gene'] = nil
    fs_variant_dna_gene_null.raw_fields['gene (other)'] = 'APC'
    fs_variant_dna_gene_null.raw_fields['variant dna'] = 'c.3920T>A'
    @handler.assign_test_status_fullscreen(fs_variant_dna_gene_null, @genotype, { 'gene' => [], 'gene (other)' => ['APC'], 'variant dna' => ['c.3920T>A'], 'test/panel' => [] }, 'gene (other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_dna_gene_null = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_gene_null.raw_fields['gene'] = nil
    fs_variant_dna_gene_null.raw_fields['gene (other)'] = 'APC, BMPR1A, EPCAM, MLH1, MSH2, MSH6, MUTYH, NTHL1'
    fs_variant_dna_gene_null.raw_fields['variant dna'] = 'c.3920T>A'
    @handler.assign_test_status_fullscreen(fs_variant_dna_gene_null, @genotype, { 'gene' => [], 'gene (other)' => ['APC, BMPR1A, EPCAM, MLH1, MSH2, MSH6, MUTYH, NTHL1'], 'variant dna' => [], 'test/panel' => [] }, 'gene (other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_protein_fail = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_protein_fail.raw_fields['variant protein'] = 'Fail'
    fs_variant_protein_fail.raw_fields['gene'] = 'APC'
    fs_variant_protein_fail.raw_fields['variant dna'] = nil
    @handler.assign_test_status_fullscreen(fs_variant_protein_fail, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }, 'gene')
    assert_equal 9, @genotype.attribute_map['teststatus']

    fs_variant_protein_p = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_protein_p.raw_fields['variant protein'] = 'p.(Thr328Ter)'
    fs_variant_protein_p.raw_fields['gene'] = 'APC'
    fs_variant_protein_p.raw_fields['variant dna'] = nil
    @handler.assign_test_status_fullscreen(fs_variant_protein_p, @genotype, { 'gene' => [], 'gene (other)' => [], 'variant dna' => [], 'variant protein' => ['p.(Thr328Ter)'], 'test/panel' => [] }, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_protein_else = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_protein_else.raw_fields['variant protein'] = 'no result'
    fs_variant_protein_else.raw_fields['gene'] = 'APC'
    @handler.assign_test_status_fullscreen(fs_variant_protein_else, @genotype, { 'gene' => [], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }, 'gene')
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'assign_test_status_targeted' do
    targ_gene_other_fail = build_raw_record('pseudo_id1' => 'bob')
    targ_gene_other_fail.raw_fields['variant dna'] = nil
    targ_gene_other_fail.raw_fields['gene'] = nil
    targ_gene_other_fail.raw_fields['gene (other)'] = 'Failed sample'
    @handler.assign_test_status_targeted(targ_gene_other_fail, @genotype, { gene: [], 'gene (other)': ['FAIL'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene (other)', 'APC')
    assert_equal 9, @genotype.attribute_map['teststatus']

    targ_gene_other_het = build_raw_record('pseudo_id1' => 'bob')
    targ_gene_other_het.raw_fields['variant dna'] = nil
    targ_gene_other_het.raw_fields['gene'] = nil
    targ_gene_other_het.raw_fields['gene (other)'] = 'het duplication'
    @handler.assign_test_status_targeted(targ_gene_other_het, @genotype, { gene: [], 'gene (other)': ['het duplication'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene (other)', 'APC')
    assert_equal 2, @genotype.attribute_map['teststatus']

    # variant dna is fail, gene is APC and gene(other) is nil
    targ_variant_dna_fail = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_dna_fail.raw_fields['variant dna'] = 'samples failed'
    targ_variant_dna_fail.raw_fields['gene'] = 'APC'
    targ_variant_dna_fail.raw_fields['gene (other)'] = nil
    @handler.assign_test_status_targeted(targ_variant_dna_fail, @genotype, { gene: [], 'gene (other)': [], 'variant dna': ['samples failed'], 'variant protein': [], 'test/panel' => [] }, 'variant dna', 'APC')
    assert_equal 9, @genotype.attribute_map['teststatus']

    # benign SNP noted in data, must be given unknown (4) instead of matching the c.
    targ_variant_dna_snp_present = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_dna_snp_present.raw_fields['variant dna'] = 'c.1284T>C SNP present'
    targ_variant_dna_snp_present.raw_fields['gene'] = 'APC'
    targ_variant_dna_snp_present.raw_fields['gene (other)'] = 'EPCAM'
    @handler.assign_test_status_targeted(targ_variant_dna_snp_present, @genotype, { gene: [], 'gene (other)': [], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'variant dna', 'APC')
    assert_equal 4, @genotype.attribute_map['teststatus']

    # real c. in variant dna, test for assigning 2
    targ_variant_dna_c = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_dna_c.raw_fields['variant dna'] = 'c.1256A>G'
    targ_variant_dna_c.raw_fields['gene'] = 'APC'
    targ_variant_dna_c.raw_fields['gene (other)'] = 'EPCAM'
    @handler.assign_test_status_targeted(targ_variant_dna_c, @genotype, { gene: [], 'gene (other)': [], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'variant dna', 'APC')
    assert_equal 2, @genotype.attribute_map['teststatus']

    # real variant in variant dna, test for assigning 2
    targ_variant_dna_ex_inv = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_dna_ex_inv.raw_fields['variant dna'] = 'Exon 12 inversion'
    targ_variant_dna_ex_inv.raw_fields['gene'] = 'APC'
    targ_variant_dna_ex_inv.raw_fields['gene (other)'] = 'EPCAM'
    targ_variant_dna_ex_inv.raw_fields['gene (other)'] = 'EPCAM'
    @handler.assign_test_status_targeted(targ_variant_dna_ex_inv, @genotype, { gene: [], 'gene (other)': [], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'variant dna', 'APC')
    assert_equal 2, @genotype.attribute_map['teststatus']

    # variant (p.) is in protein dna column and gene is in variant dna column
    targ_variant_protein_p = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_protein_p.raw_fields['variant dna'] = 'APC'
    targ_variant_protein_p.raw_fields['gene'] = ''
    targ_variant_protein_p.raw_fields['gene (other)'] = 'EPCAM'
    targ_variant_protein_p.raw_fields['variant protein'] = 'p.256Arg>Thr'
    @handler.assign_test_status_targeted(targ_variant_protein_p, @genotype, { gene: [], 'gene (other)': [], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'variant dna', 'APC')
    assert_equal 1, @genotype.attribute_map['teststatus']

    # variant (p.) is in protein dna column and gene is in gene column
    targ_variant_protein_p = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_protein_p.raw_fields['variant dna'] = ''
    targ_variant_protein_p.raw_fields['gene'] = 'APC'
    targ_variant_protein_p.raw_fields['gene (other)'] = 'EPCAM'
    targ_variant_protein_p.raw_fields['variant protein'] = 'p.256Arg>Thr'
    @handler.assign_test_status_targeted(targ_variant_protein_p, @genotype, { gene: [], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene', 'APC')
    assert_equal 2, @genotype.attribute_map['teststatus']

    # fail in variant protein column
    targ_variant_protein_fail = build_raw_record('pseudo_id1' => 'bob')
    targ_variant_protein_fail.raw_fields['variant dna'] = ''
    targ_variant_protein_fail.raw_fields['gene'] = 'APC'
    targ_variant_protein_fail.raw_fields['gene (other)'] = 'EPCAM'
    targ_variant_protein_fail.raw_fields['variant protein'] = 'failed test'
    @handler.assign_test_status_targeted(targ_variant_protein_fail, @genotype, { gene: ['APC'], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene', 'APC')
    assert_equal 9, @genotype.attribute_map['teststatus']

    # no variant noted in any column
    targ_no_variant = build_raw_record('pseudo_id1' => 'bob')
    targ_no_variant.raw_fields['variant dna'] = ''
    targ_no_variant.raw_fields['gene'] = 'APC'
    targ_no_variant.raw_fields['gene (other)'] = 'EPCAM'
    targ_no_variant.raw_fields['variant protein'] = ''
    @handler.assign_test_status_targeted(targ_no_variant, @genotype, { gene: ['APC'], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'variant protein', 'APC')
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'interrogate_gene_other_targeted' do
    int_gene_other_fail = build_raw_record('pseudo_id1' => 'bob')
    int_gene_other_fail.raw_fields['variant dna'] = ''
    int_gene_other_fail.raw_fields['gene'] = 'APC'
    int_gene_other_fail.raw_fields['gene (other)'] = 'Fail'
    @handler.interrogate_gene_other_targeted(int_gene_other_fail, @genotype, { gene: ['APC'], 'gene (other)': ['Fail'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene (other)', 'APC')
    assert_equal 9, @genotype.attribute_map['teststatus']

    int_gene_other_match = build_raw_record('pseudo_id1' => 'bob')
    int_gene_other_match.raw_fields['variant dna'] = ''
    int_gene_other_match.raw_fields['gene'] = 'APC'
    int_gene_other_match.raw_fields['gene (other)'] = 'c.123A>C'
    @handler.interrogate_gene_other_targeted(int_gene_other_match, @genotype, { gene: ['APC'], 'gene (other)': ['c.123A>C'], 'variant dna': [], 'variant protein': [], 'test/panel' => [] }, 'gene (other)', 'APC')
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'interrogate_variant_dna_targeted' do
    int_variant_dna_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_fail.raw_fields['variant dna'] = 'Blank contamination'
    int_variant_dna_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_targeted(int_variant_dna_fail, @genotype, 'variant dna')
    assert_equal 9, @genotype.attribute_map['teststatus']

    int_variant_dna_normal = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_normal.raw_fields['variant dna'] = 'no del/dup'
    int_variant_dna_normal.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_targeted(int_variant_dna_normal, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    int_variant_dna_see_comments = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_see_comments.raw_fields['variant dna'] = 'see comments'
    int_variant_dna_see_comments.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_targeted(int_variant_dna_see_comments, @genotype, 'variant dna')
    assert_equal 4, @genotype.attribute_map['teststatus']

    int_variant_dna_dup = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_dup.raw_fields['variant dna'] = 'Exon 4 duplication'
    int_variant_dna_dup.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_targeted(int_variant_dna_dup, @genotype, 'variant dna')
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'interrogate_variant_protein_targeted' do
    int_variant_protein_p = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_p.raw_fields['variant protein'] = 'p.(Thr328Ter)'
    int_variant_protein_p.raw_fields['gene'] = 'APC'
    int_variant_protein_p.raw_fields['gene (other)'] = 'EPCAM'
    @handler.interrogate_variant_protein_targeted(int_variant_protein_p, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    int_variant_protein_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fail.raw_fields['variant protein'] = 'FAIL'
    int_variant_protein_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_targeted(int_variant_protein_fail, @genotype, 'gene')
    assert_equal 9, @genotype.attribute_map['teststatus']

    int_variant_protein_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fail.raw_fields['variant protein'] = ''
    int_variant_protein_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_targeted(int_variant_protein_fail, @genotype, 'gene')
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'interrogate_variant_dna_fullscreen' do
    int_variant_dna_fs_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_fs_fail.raw_fields['variant dna'] = 'Fail'
    int_variant_dna_fs_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_fullscreen(int_variant_dna_fs_fail, @genotype, { gene: ['APC'], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': ['Fail'], 'test/panel' => [] }, 'variant dna')
    assert_equal 9, @genotype.attribute_map['teststatus']

    int_variant_dna_fs_n = build_raw_record('pseudo_id1' => 'bob')
    int_variant_dna_fs_n.raw_fields['variant dna'] = 'N'
    int_variant_dna_fs_n.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_dna_fullscreen(int_variant_dna_fs_n, @genotype, { gene: ['APC'], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': ['Fail'], 'test/panel' => [] }, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'handle_gene_status_full_screen' do
    handle_gene_fs_present = build_raw_record('pseudo_id1' => 'bob')
    handle_gene_fs_present.raw_fields['variant dna'] = 'c.123A>C'
    handle_gene_fs_present.raw_fields['gene'] = 'APC'
    @handler.handle_gene_status_full_screen(handle_gene_fs_present, @genotype, { gene: ['APC'], 'gene (other)': ['EPCAM'], 'variant dna': [], 'variant protein': ['Fail'], 'test/panel' => [] }, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'handle_gene_other_status_full_screen' do
    handle_geneother_fs_lenght1 = build_raw_record('pseudo_id1' => 'bob')
    handle_geneother_fs_lenght1.raw_fields['gene'] = nil
    handle_geneother_fs_lenght1.raw_fields['gene (other)'] = 'EPCAM'
    handle_geneother_fs_lenght1.raw_fields['variant dna'] = 'c.123A>C'
    @handler.handle_gene_other_status_full_screen(handle_geneother_fs_lenght1, @genotype, { 'gene' => [], 'gene (other)' => ['EPCAM'], 'variant dna' => [], 'test/panel' => [] }, 'gene (other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    handle_geneother_fs_grt_one = build_raw_record('pseudo_id1' => 'bob')
    handle_geneother_fs_grt_one.raw_fields['gene'] = nil
    handle_geneother_fs_grt_one.raw_fields['gene (other)'] = 'EPCAM, MLH1'
    handle_geneother_fs_grt_one.raw_fields['variant dna'] = 'c.123A>C'
    @handler.handle_gene_other_status_full_screen(handle_geneother_fs_grt_one, @genotype, { 'gene' => [], 'gene (other)' => ['EPCAM, MLH1'], 'variant dna' => [], 'test/panel' => [] }, 'gene (other)')
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'interrogate_variant_protein_fullscreen' do
    int_variant_protein_fs_blank = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fs_blank.raw_fields['variant protein'] = ''
    int_variant_protein_fs_blank.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_fullscreen(int_variant_protein_fs_blank, @genotype, 'gene')
    assert_equal 1, @genotype.attribute_map['teststatus']

    int_variant_protein_fs_p = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fs_p.raw_fields['variant protein'] = 'p.(Thr328Ter)'
    int_variant_protein_fs_p.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_fullscreen(int_variant_protein_fs_p, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    int_variant_protein_fs_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fs_fail.raw_fields['variant protein'] = 'Fail'
    int_variant_protein_fs_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_fullscreen(int_variant_protein_fs_fail, @genotype, 'gene')
    assert_equal 9, @genotype.attribute_map['teststatus']

    int_variant_protein_fs_fail = build_raw_record('pseudo_id1' => 'bob')
    int_variant_protein_fs_fail.raw_fields['variant protein'] = 'hello'
    int_variant_protein_fs_fail.raw_fields['gene'] = 'APC'
    @handler.interrogate_variant_protein_fullscreen(int_variant_protein_fs_fail, @genotype, 'gene')
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'process_variants' do
    # variant dna and variant protein columns
    cvalue_pvalue_present = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    cvalue_pvalue_present.raw_fields['variant dna'] = 'c.3477C>G'
    cvalue_pvalue_present.raw_fields['variant protein'] = 'p.(Tyr1159Ter)'
    @handler.process_variants(@genotype, cvalue_pvalue_present)
    assert_equal 'c.3477C>G', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Tyr1159Ter', @genotype.attribute_map['proteinimpact']

    # no c or p value, check process_zygosity runs correctly
    no_c_or_p_value = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    no_c_or_p_value.raw_fields['variant dna'] = 'Ex 09-10 het del, confirm by MLPA'
    @handler.process_variants(@genotype, no_c_or_p_value)
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal '09-10', @genotype.attribute_map['exonintroncodonnumber']
  end

  test 'process_location_type' do
    # when variant is in variant dna column
    location_variant_dna_column = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    location_variant_dna_column.raw_fields['variant dna'] = 'Het Dup Ex1-6'
    @handler.process_variants(@genotype, location_variant_dna_column)
    assert_equal 4, @genotype.attribute_map['sequencevarianttype']
    assert_equal '1-6', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 1, @genotype.attribute_map['variantlocation']

    # when variant is in gene (other) column
    location_variant_dna_column = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    location_variant_dna_column.raw_fields['gene (other)'] = 'HET DEL EX7'
    @handler.process_variants(@genotype, location_variant_dna_column)
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal '7', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 1, @genotype.attribute_map['variantlocation']
  end

  def clinical_json
    +
    {}.to_json
  end

  def rawtext_clinical_json
    {}.to_json
  end
end
