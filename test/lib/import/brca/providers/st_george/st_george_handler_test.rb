require 'test_helper'

class StGeorgeHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::StGeorge::StGeorgeHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'process_fields' do
    valid_sri_record = build_raw_record('pseudo_id1' => 'bob')
    genotypes = @handler.process_fields(valid_sri_record)
    assert_equal 'V1234', genotypes[0].attribute_map['servicereportidentifier']

    invalid_sri_record = build_raw_record('pseudo_id1' => 'bob')
    invalid_sri_record.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    invalid_sri_record.raw_fields['servicereportidentifier'] = 'W1234'
    valid_sri_record.raw_fields['gene'] = 'BRCA1'
    genotypes = @handler.process_fields(invalid_sri_record)
    assert_nil genotypes
  end

  test 'fill_genotypes' do
    targeted = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['genetictestscope'] = 'Targeted BRCA mutation test'
    targeted.raw_fields['gene'] = 'BRCA2 PALB2'
    targeted.raw_fields['gene (other)'] = 'positive control failed'
    genotypes = @handler.fill_genotypes(@genotype, targeted)
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 3186, genotypes[1].attribute_map['gene']
    assert_equal 9, genotypes[1].attribute_map['teststatus']

    fullscreen = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['genetictestscope'] = 'Full screen BRCA1 and BRCA2'
    fullscreen.raw_fields['variant dna'] = 'value'
    fullscreen.raw_fields['gene'] = 'BRCA1'
    fullscreen.raw_fields['gene (other)'] = nil
    genotypes = @handler.fill_genotypes(@genotype, fullscreen)
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
  end

  test 'assign_test_type' do
    diagnostic_record1 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record1.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    @handler.assign_test_type(@genotype, diagnostic_record1)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record2 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record2.raw_fields['moleculartestingtype'] = 'Family follow-up testing to aid variant interpretation'
    @handler.assign_test_type(@genotype, diagnostic_record2)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record3 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record3.raw_fields['moleculartestingtype'] = 'Inherited breast cancer and ovarian cancer'
    @handler.assign_test_type(@genotype, diagnostic_record3)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record4 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record4.raw_fields['moleculartestingtype'] = 'Inherited ovarian cancer (without breast cancer)'
    @handler.assign_test_type(@genotype, diagnostic_record4)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    predictive_record = build_raw_record('pseudo_id1' => 'bob')
    predictive_record.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    @handler.assign_test_type(@genotype, predictive_record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']

    predictive_record = build_raw_record('pseudo_id1' => 'bob')
    predictive_record.raw_fields['moleculartestingtype'] = 'NICE approved PARP inhibitor treatment'
    @handler.assign_test_type(@genotype, predictive_record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  test 'assign_test_scope' do
    testscope_no_scope_record = build_raw_record('pseudo_id1' => 'bob')
    testscope_no_scope_record.raw_fields['moleculartestingtype'] = 'no genetic test scope'
    @logger.expects(:error).with('ERROR - record with no genetic test scope, ask Fiona for new rules')
    @handler.assign_test_scope(@genotype, testscope_no_scope_record)

    testscope_targeted_record1 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record1.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    @handler.assign_test_scope(@genotype, testscope_targeted_record1)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    testscope_targeted_record2 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record2.raw_fields['moleculartestingtype'] = 'Family follow-up testing to aid variant interpretation'
    @handler.assign_test_scope(@genotype, testscope_targeted_record2)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    testscope_targeted_record3 = build_raw_record('pseudo_id1' => 'bob')
    testscope_targeted_record3.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    @handler.assign_test_scope(@genotype, testscope_targeted_record3)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    testscope_fs_record1 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record1.raw_fields['moleculartestingtype'] = 'Inherited breast cancer and ovarian cancer'
    @handler.assign_test_scope(@genotype, testscope_fs_record1)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    testscope_fs_record2 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record2.raw_fields['moleculartestingtype'] = 'Inherited ovarian cancer (without breast cancer)'
    @handler.assign_test_scope(@genotype, testscope_fs_record2)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    testscope_fs_record3 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record3.raw_fields['moleculartestingtype'] = 'NICE approved PARP inhibitor treatment'
    @handler.assign_test_scope(@genotype, testscope_fs_record3)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    testscope_fs_record4 = build_raw_record('pseudo_id1' => 'bob')
    testscope_fs_record4.raw_fields['moleculartestingtype'] = 'Inherited prostate cancer'
    @handler.assign_test_scope(@genotype, testscope_fs_record4)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
  end

  test 'process_genes_targeted' do
    targeted_brca1_record_empty_gene_other = build_raw_record('pseudo_id1' => 'bob')
    targeted_brca1_record_empty_gene_other.raw_fields['gene'] = 'BRCA1'
    targeted_brca1_record_empty_gene_other.raw_fields['gene (other)'] = nil
    genes = @handler.process_genes_targeted(targeted_brca1_record_empty_gene_other)
    assert_equal [['BRCA1']], genes

    targeted_brca1_record_empty_gene = build_raw_record('pseudo_id1' => 'bob')
    targeted_brca1_record_empty_gene.raw_fields['gene'] = nil
    targeted_brca1_record_empty_gene.raw_fields['gene (other)'] = 'BRCA1'
    genes = @handler.process_genes_targeted(targeted_brca1_record_empty_gene)
    assert_equal [['BRCA1']], genes

    targeted_incorrect_gene_name = build_raw_record('pseudo_id1' => 'bob')
    targeted_incorrect_gene_name.raw_fields['gene'] = 'PLAB2'
    targeted_incorrect_gene_name.raw_fields['gene (other)'] = 'BRCA2'
    genes = @handler.process_genes_targeted(targeted_incorrect_gene_name)
    assert_equal [['PALB2'], ['BRCA2']], genes
  end

  test 'duplicate_genotype_targeted' do
    genotypes = []
    genotypes = @handler.duplicate_genotype_targeted([['PALB2'], ['BRCA2']], @genotype, genotypes)
    assert_equal 2, genotypes.length

    genotypes = @handler.duplicate_genotype_targeted([['BRCA2']], @genotype, genotypes)
    assert_equal 1, genotypes.length
  end

  test 'assign_test_status_targeted' do
    # Priority 1: Fail in gene(other)
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'FAIL'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 1: Fail in gene(other)
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'positive control failed'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 1: Fail in gene(other)
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'wronng exon'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 1: het in gene(other)
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'het'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    # Priority 2: Fail in variant dna
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = 'FAIL'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 2: wrong amplicon tested in variant dna
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = 'wrong amplicon tested'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 2: wrong amplicon tested in variant dna
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = 'incorrect panel sequenced'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    # Priority 2: N in variant dna
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = 'N'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 1, @genotype.attribute_map['teststatus']

    # Priority 2: dup in variant dna
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = 'dup'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    # Priority 3: N in variant protein
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = ''
    targeted.raw_fields['variant protein'] = 'N'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 1, @genotype.attribute_map['teststatus']

    # Priority 3: p. in variant protein
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = ''
    targeted.raw_fields['variant protein'] = 'p.1234'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    # Priority 3: blank in variant protein
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = ''
    targeted.raw_fields['variant dna'] = ''
    targeted.raw_fields['variant protein'] = ''
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 4, @genotype.attribute_map['teststatus']
  end

  test 'process_genes_full_screen' do
    fs_brca1_record = build_raw_record('pseudo_id1' => 'bob')
    fs_brca1_record.raw_fields['gene'] = 'BRCA1 PALB2'
    fs_brca1_record.raw_fields['gene (other)'] = 'unknown'
    genes_dict = @handler.process_genes_full_screen(fs_brca1_record)
    assert_equal ({ 'gene' => %w[BRCA1 PALB2], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }), genes_dict

    fs_brca1_slash_brca2_record = build_raw_record('pseudo_id1' => 'bob')
    fs_brca1_slash_brca2_record.raw_fields['gene'] = 'BRCA1/2'
    fs_brca1_slash_brca2_record.raw_fields['gene (other)'] = 'unknown'
    genes_dict = @handler.process_genes_full_screen(fs_brca1_slash_brca2_record)
    assert_equal ({ 'gene' => %w[BRCA1 BRCA2], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }), genes_dict

    fs_brca1_plus_brca2_record = build_raw_record('pseudo_id1' => 'bob')
    fs_brca1_plus_brca2_record.raw_fields['gene'] = 'BRCA1+2'
    fs_brca1_plus_brca2_record.raw_fields['gene (other)'] = 'unknown'
    genes_dict = @handler.process_genes_full_screen(fs_brca1_plus_brca2_record)
    assert_equal ({ 'gene' => %w[BRCA1 BRCA2], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }), genes_dict

    # TODO- what would be the outcome if the same gene was in two different columns?
    fs_brca1_plus_brca2_record = build_raw_record('pseudo_id1' => 'bob')
    fs_brca1_plus_brca2_record.raw_fields['gene'] = 'BRCA1+2, BRCA1'
    fs_brca1_plus_brca2_record.raw_fields['gene (other)'] = 'unknown'
    genes_dict = @handler.process_genes_full_screen(fs_brca1_plus_brca2_record)
    assert_equal ({ 'gene' => %w[BRCA1 BRCA2], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] }), genes_dict
  end

  test 'process_test_panels' do
    hboc_v1_panel = build_raw_record('pseudo_id1' => 'bob')
    hboc_v1_panel.raw_fields['test/panel'] = 'HBOC_V1'
    genes = @handler.process_test_panels(hboc_v1_panel, [], 'test/panel')
    assert_equal %w[BRCA1 BRCA2 CHEK2 PALB2], genes

    r207_panel = build_raw_record('pseudo_id1' => 'bob')
    r207_panel.raw_fields['test/panel'] = 'R207'
    genes = @handler.process_test_panels(r207_panel, ['CHEK2'], 'test/panel')
    assert_equal %w[CHEK2 BRCA1 BRCA2 BRIP1 MLH1 MSH2 MSH6 PALB2 RAD51C RAD51D], genes

    r208c_panel = build_raw_record('pseudo_id1' => 'bob')
    r208c_panel.raw_fields['test/panel'] = 'R208+C'
    genes = @handler.process_test_panels(r208c_panel, [], 'test/panel')
    assert_equal %w[BRCA1 BRCA2 CHEK2 PALB2], genes

    r430_panel = build_raw_record('pseudo_id1' => 'bob')
    r430_panel.raw_fields['test/panel'] = 'R430'
    genes = @handler.process_test_panels(r430_panel, [], 'test/panel')
    assert_equal %w[BRCA1 BRCA2 MLH1 MSH2 MSH6 ATM PALB2 CHEK2], genes

    r444_1_panel = build_raw_record('pseudo_id1' => 'bob')
    r444_1_panel.raw_fields['test/panel'] = 'R444.1'
    genes = @handler.process_test_panels(r444_1_panel, [], 'test/panel')
    assert_equal %w[BRCA1 BRCA2 PALB2 RAD51C RAD51D ATM CHEK2], genes

    r444_2_panel = build_raw_record('pseudo_id1' => 'bob')
    r444_2_panel.raw_fields['test/panel'] = 'R444.2'
    genes = @handler.process_test_panels(r444_2_panel, [], 'test/panel')
    assert_equal %w[BRCA1 BRCA2], genes

    blank_panel = build_raw_record('pseudo_id1' => 'bob')
    blank_panel.raw_fields['test/panel'] = ''
    genes = @handler.process_test_panels(blank_panel, [], 'test/panel')
    assert_equal %w[], genes
  end

  test 'process_r208' do
    r208_first_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_first_panel.raw_fields['test/panel'] = 'R208'
    r208_first_panel.raw_fields['authoriseddate'] = '09/07/2022'
    genes = @handler.process_r208(r208_first_panel)
    assert_equal %w[BRCA1 BRCA2], genes

    r208_second_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_second_panel.raw_fields['test/panel'] = 'R208'
    r208_second_panel.raw_fields['authoriseddate'] = '01/08/2022'
    genes = @handler.process_r208(r208_second_panel)
    assert_equal %w[BRCA1 BRCA2 CHEK2 PALB2 ATM], genes

    r208_third_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_third_panel.raw_fields['test/panel'] = 'R208'
    r208_third_panel.raw_fields['authoriseddate'] = '01/01/2023'
    genes = @handler.process_r208(r208_third_panel)
    assert_equal %w[BRCA1 BRCA2 CHEK2 PALB2 ATM RAD51C RAD51D], genes
  end

  test 'assign_test_status_full_screen' do
    fs_gene_column = build_raw_record('pseudo_id1' => 'bob')
    fs_gene_column.raw_fields['gene'] = 'BRCA1'
    fs_gene_column.raw_fields['gene (other)'] = 'unknown'
    @handler.assign_test_scope(@genotype, fs_gene_column)
    genotypes = @handler.fill_genotypes(@genotype, fs_gene_column)
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes.length

    fs_gene_other_column = build_raw_record('pseudo_id1' => 'bob')
    fs_gene_other_column.raw_fields['gene'] = 'unknown'
    fs_gene_other_column.raw_fields['gene (other)'] = 'BRCA1'
    @handler.assign_test_scope(@genotype, fs_gene_other_column)
    genotypes = @handler.fill_genotypes(@genotype, fs_gene_other_column)
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes.length

    # check the duplication is working correctly
    multiple_genes = build_raw_record('pseudo_id1' => 'bob')
    multiple_genes.raw_fields['gene'] = 'BRCA1'
    multiple_genes.raw_fields['gene (other)'] = 'BRCA2'
    @handler.assign_test_scope(@genotype, multiple_genes)
    genotypes = @handler.fill_genotypes(@genotype, multiple_genes)
    assert_equal 2, genotypes.length
  end

  test 'assign test status based on variant dna' do
    # Test when variant dna column contains fail
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1 tested. All genes have Failed'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 9, genotypes[0].attribute_map['teststatus']

    # Test when variant dna column contains N
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'N'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 1, genotypes[0].attribute_map['teststatus']

    # Test when [raw:gene is not null] AND [raw:gene (other) is null]
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BR1 Ex1-2 del'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene (other)'] = nil
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']

    # [Is not '*Fail*', 'N' or null] AND [raw:gene is not null] AND [raw:gene (other) is not null]

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'PALB2: c.1675C>T'
    full_screen_test_status.raw_fields['gene'] = 'PALB2'
    full_screen_test_status.raw_fields['gene (other)'] = '(TP53 at GOSH)'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 3186, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 79, genotypes[1].attribute_map['gene']

    # [raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene (other) column but not failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BR1? Ex7-12 del'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene (other)'] = 'BRCA2 FAIL'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 9, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']

    # Test when raw:gene is null] AND raw:gene (other) specifies a single gene and the gene in question is in the gene(other column)
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'variant'
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'ATM'
    full_screen_test_status.raw_fields['test/panel'] = 'R208'

    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 7, genotypes.size
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 451, genotypes[0].attribute_map['gene']

    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']

    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_equal 8, genotypes[2].attribute_map['gene']

    # Test when raw:gene is null] AND raw:gene (other) does not specify a single gene

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'c.2269del'
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'BRCA1 Class V, BRCA2 N'
    full_screen_test_status.raw_fields['test/panel'] = 'BRCA1/2_V1'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']

    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']

    # Test when raw:gene is null] AND raw:gene (other) does not specify a single gene but varaint dna has gene

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1 EX3 Del'
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'PALB2/BRCA2 normal'
    full_screen_test_status.raw_fields['test/panel'] = 'RPKM'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']

    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 3186, genotypes[1].attribute_map['gene']

    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_equal 8, genotypes[2].attribute_map['gene']
  end

  test 'assign test status based on gene (other)' do
    # tests when there is a fail in gene (other) column, and the gene in question has failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene (other)'] = 'PALB2 FAIL'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 3186, genotypes[0].attribute_map['gene']

    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']

    # tests when there is a fail and more than one gene in gene (other) column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'ATM BRCA1/2 FAIL'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 9, genotypes[1].attribute_map['teststatus']
    assert_equal 9, genotypes[2].attribute_map['teststatus']

    # test when there is fail in gene (other) column with no gene specified and there is gene listed in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA2'
    full_screen_test_status.raw_fields['gene (other)'] = 'FAIL'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 10, genotypes[0].attribute_map['teststatus']

    # test when the regex matches the gene (other) column and the gene is in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene (other)'] = 'c.1234'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']

    # test when the value in gene (other) is in the format 'gene Class V, gene N'
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'BRCA1 Class V, ATM N'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']

    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 451, genotypes[1].attribute_map['gene']

    # test when exonic variant is reported in gene_other
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA2'
    full_screen_test_status.raw_fields['gene (other)'] = 'Hetdel ex 25'
    full_screen_test_status.raw_fields['test/panel'] = 'RPKM_0723'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']

    # test assigning test status of 4 when none of the scenarios above fit
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene (other)'] = 'unknown'
    full_screen_test_status.raw_fields['test/panel'] = 'BRCA1/2_V1'
    @handler.assign_test_scope(@genotype, full_screen_test_status)
    genotypes = @handler.fill_genotypes(@genotype, full_screen_test_status)
    assert_equal 4, genotypes[0].attribute_map['teststatus']
    assert_equal 4, genotypes[1].attribute_map['teststatus']
  end

  test 'process_variants' do
    # variant dna and variant protein columns
    cvalue_pvalue_present1 = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    cvalue_pvalue_present1.raw_fields['variant dna'] = 'c.1234A<G'
    cvalue_pvalue_present1.raw_fields['variant protein'] = 'p.1234Arg123Gly'
    @handler.process_variants(@genotype, cvalue_pvalue_present1)
    assert_equal 'c.1234A<G', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.1234Arg123Gly', @genotype.attribute_map['proteinimpact']

    # gene and variant dna columns
    cvalue_pvalue_present2 = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    cvalue_pvalue_present2.raw_fields['gene'] = 'c.1234A<G'
    cvalue_pvalue_present2.raw_fields['variant dna'] = 'p.1234Arg123Gly'
    @handler.process_variants(@genotype, cvalue_pvalue_present2)
    assert_equal 'c.1234A<G', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.1234Arg123Gly', @genotype.attribute_map['proteinimpact']

    # gene and gene(other) columns
    cvalue_pvalue_present3 = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    cvalue_pvalue_present3.raw_fields['gene'] = 'c.1234A<G'
    cvalue_pvalue_present3.raw_fields['gene(other)'] = 'p.1234Arg123Gly'
    @handler.process_variants(@genotype, cvalue_pvalue_present3)
    assert_equal 'c.1234A<G', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.1234Arg123Gly', @genotype.attribute_map['proteinimpact']

    # check process_location_type runs ok from this function
    cvalue_pvalue_absent = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    cvalue_pvalue_absent.raw_fields['variant dna'] = 'het del ex 12-34'
    @handler.process_variants(@genotype, cvalue_pvalue_absent)
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal '12-34', @genotype.attribute_map['exonintroncodonnumber']
  end

  test 'process_location_type' do
    location_type = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    location_type.raw_fields['gene'] = 'het del ex 12-34'
    @handler.process_variants(@genotype, location_type)
    assert_nil @genotype.attribute_map['sequencevarianttype']
    assert_nil @genotype.attribute_map['exonintroncodonnumber']
    assert_nil @genotype.attribute_map['variantgenotype']

    location_type = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus'] = 2
    location_type.raw_fields['variant dna'] = 'het del ex 12-34'
    @handler.process_variants(@genotype, location_type)
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal '12-34', @genotype.attribute_map['exonintroncodonnumber']
  end

  def clinical_json
    { 'sex' => '2',
      'consultantcode' => 'C9999998',
      'providercode' => 'providercode',
      'collecteddate' => '2023-07-04T00:00:00.000+01:00',
      'receiveddate' => '2023-07-05T00:00:00.000+01:00',
      'authoriseddate' => '2023-08-22T00:00:00.000+01:00',
      'servicereportidentifier' => 'V1234',
      'sortdate' => '2023-07-05T00:00:00.000+01:00',
      'specimentype' => '5',
      'age' => 41 }.to_json
  end

  def rawtext_clinical_json
    { 'sex' => 'Female',
      'g number' => 'g numbe',
      'providercode' => 'providercode',
      'referral organisation' => "St George's Hospital",
      'consultantname' => 'XYZ',
      'servicereportidentifier' => 'V1234',
      'receiveddate' => '2023-07-05 16:38:55',
      'collecteddate' => '2023-07-04 09:43:00',
      'authoriseddate' => '2023-08-22 14:31:20',
      'specimentype' => 'Blood',
      'test/panel' => 'MLPA',
      'gene' => 'ATM',
      'gene (other)' => 'kit 2',
      'variant dna' => 'N',
      'variant protein' => 'N',
      'moleculartestingtype' => 'Inherited breast cancer and ovarian cancer' }.to_json
  end
end
