require 'test_helper'
# require 'import/genotype.rb'
# require 'import/brca/core/provider_handler'

class NewcastleHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Newcastle::NewcastleHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_protein_impact' do
    @logger.expects(:debug).with('FAILED protein parse for: c.2597G>A')
    variant = @handler.get_variant(@record)
    @handler.process_protein_impact(@genotype, variant)
    protein_record = build_raw_record('pseudo_id1' => 'bob')
    protein_record.raw_fields['genotype'] = 'c.2597G>A;p.Thr2968fsX8'
    variant_p = @handler.get_variant(protein_record)
    @logger.expects(:debug).with('SUCCESSFUL protein parse for: Thr2968fsX8')
    @handler.process_protein_impact(@genotype, variant_p)
    assert_equal 'p.Thr2968fsx8', @genotype.attribute_map['proteinimpact']
  end

  test 'process_cdna_variant' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 2597G>A')
    variant = @handler.get_variant(@record)
    @handler.process_cdna_variant(@genotype, variant)
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'process_test_scope' do
    @logger.expects(:debug).with('Found O/C')
    @handler.process_test_scope(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    type_record = build_raw_record('pseudo_id1' => 'bob')
    type_record.raw_fields['service category'] = 'B'
    @handler.process_test_scope(@genotype, type_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['service category'] = 'B'
    targeted_record.raw_fields['moleculartestingtype'] = 'Carrier'
    @logger.expects(:info).with('ADDED SCOPE FROM INVESTIGATION CODE/MOLECULAR TESTING TYPE')
    @handler.process_test_scope(@genotype, targeted_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']
  end

  test 'process_variant_records' do
    # @handler.add_gene_info(@genotype, @record)
    @handler.process_test_scope(@genotype, @record)
    genotypes = @handler.process_variant_records(@genotype, @record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 2, genotypes.size
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 7, genotypes[1].attribute_map['gene']
  end

  test 'process_test_type' do
    @handler.process_test_type(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']
  end

  test 'process_nmd_record_withnogene_nomutation' do
    nmd_no_mutationrecord = build_raw_record('pseudo_id1' => 'bob')
    nmd_no_mutationrecord.raw_fields['moleculartestingtype'] = 'presymptomatic'
    nmd_no_mutationrecord.raw_fields['service category'] = 'B'
    nmd_no_mutationrecord.raw_fields['investigation code'] = 'BRCA-PRED'
    nmd_no_mutationrecord.raw_fields['gene'] = ''
    nmd_no_mutationrecord.raw_fields['genotype'] = ''
    nmd_no_mutationrecord.raw_fields['variantpathclass'] = ''
    nmd_no_mutationrecord.raw_fields['teststatus'] = 'nmd'
    nmd_genotype = Import::Brca::Core::GenotypeBrca.new(nmd_no_mutationrecord)
    @handler.process_test_scope(nmd_genotype, nmd_no_mutationrecord)
    @handler.process_test_status(nmd_genotype, nmd_no_mutationrecord)
    genotypes = @handler.process_variant_records(nmd_genotype, nmd_no_mutationrecord)
    assert_equal 'Targeted BRCA mutation test', nmd_genotype.attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['gene']
  end

  test 'process_nilstatus_record_nogene_nomutation_targ' do
    nilstatus_no_mutationrecord = build_raw_record('pseudo_id1' => 'bob')
    nilstatus_no_mutationrecord.raw_fields['moleculartestingtype'] = 'presymptomatic test'
    nilstatus_no_mutationrecord.raw_fields['service category'] = 'B'
    nilstatus_no_mutationrecord.raw_fields['investigation code'] = 'BRCA'
    nilstatus_no_mutationrecord.raw_fields['gene'] = nil
    nilstatus_no_mutationrecord.raw_fields['genotype'] = nil
    nilstatus_no_mutationrecord.raw_fields['variantpathclass'] = nil
    nilstatus_no_mutationrecord.raw_fields['teststatus'] = nil
    nilstatus_genotype = Import::Brca::Core::GenotypeBrca.new(nilstatus_no_mutationrecord)
    @handler.process_test_scope(nilstatus_genotype, nilstatus_no_mutationrecord)
    @handler.process_test_status(nilstatus_genotype, nilstatus_no_mutationrecord)
    assert_equal 'Targeted BRCA mutation test', nilstatus_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(nilstatus_genotype, nilstatus_no_mutationrecord)
    genotypes = @handler.process_variant_records(nilstatus_genotype, nilstatus_no_mutationrecord)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_nilstatus_record_nogene_nomutation_fs' do
    nilstatus_no_mutation_fs = build_raw_record('pseudo_id1' => 'bob')
    nilstatus_no_mutation_fs.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    nilstatus_no_mutation_fs.raw_fields['service category'] = 'O'
    nilstatus_no_mutation_fs.raw_fields['investigation code'] = 'BRCA'
    nilstatus_no_mutation_fs.raw_fields['gene'] = ''
    nilstatus_no_mutation_fs.raw_fields['genotype'] = ''
    nilstatus_no_mutation_fs.raw_fields['variantpathclass'] = ''
    nilstatus_no_mutation_fs.raw_fields['teststatus'] = ''
    nilstatus_genotype_fs = Import::Brca::Core::GenotypeBrca.new(nilstatus_no_mutation_fs)
    @handler.process_test_scope(nilstatus_genotype_fs, nilstatus_no_mutation_fs)
    @handler.process_test_status(nilstatus_genotype_fs, nilstatus_no_mutation_fs)
    genotypes = @handler.process_variant_records(nilstatus_genotype_fs, nilstatus_no_mutation_fs)
    assert_equal 2, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_failedstatus_record_nogene_nomutation' do
    failedstatus_no_mutationrecord = build_raw_record('pseudo_id1' => 'bob')
    failedstatus_no_mutationrecord.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    failedstatus_no_mutationrecord.raw_fields['service category'] = 'A2'
    failedstatus_no_mutationrecord.raw_fields['investigation code'] = 'BRCA'
    failedstatus_no_mutationrecord.raw_fields['gene'] = ''
    failedstatus_no_mutationrecord.raw_fields['genotype'] = ''
    failedstatus_no_mutationrecord.raw_fields['variantpathclass'] = ''
    failedstatus_no_mutationrecord.raw_fields['teststatus'] = 'fail'
    failedstatus_genotype = Import::Brca::Core::GenotypeBrca.new(failedstatus_no_mutationrecord)
    @handler.process_test_scope(failedstatus_genotype, failedstatus_no_mutationrecord)
    @handler.process_test_status(failedstatus_genotype, failedstatus_no_mutationrecord)
    assert_equal 'Targeted BRCA mutation test', failedstatus_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(failedstatus_genotype, failedstatus_no_mutationrecord)
    @handler.process_variant_records(failedstatus_genotype, failedstatus_no_mutationrecord)
    assert_equal 9, failedstatus_genotype.attribute_map['teststatus']
    assert_nil failedstatus_genotype.attribute_map['gene']
    assert_nil failedstatus_genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_failedstatus_record_nogene_nomutation_fs' do
    failedstatus_no_mutationrecord_fs = build_raw_record('pseudo_id1' => 'bob')
    failedstatus_no_mutationrecord_fs.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    failedstatus_no_mutationrecord_fs.raw_fields['service category'] = 'O'
    failedstatus_no_mutationrecord_fs.raw_fields['investigation code'] = 'BRCA'
    failedstatus_no_mutationrecord_fs.raw_fields['gene'] = ''
    failedstatus_no_mutationrecord_fs.raw_fields['genotype'] = ''
    failedstatus_no_mutationrecord_fs.raw_fields['variantpathclass'] = ''
    failedstatus_no_mutationrecord_fs.raw_fields['teststatus'] = 'fail'
    failedstatus_genotype_fs = Import::Brca::Core::GenotypeBrca.new(failedstatus_no_mutationrecord_fs)
    @handler.process_test_scope(failedstatus_genotype_fs, failedstatus_no_mutationrecord_fs)
    @handler.process_test_status(failedstatus_genotype_fs, failedstatus_no_mutationrecord_fs)
    genotypes = @handler.process_variant_records(failedstatus_genotype_fs, failedstatus_no_mutationrecord_fs)
    assert_equal 2, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 9, genotypes[0].attribute_map['teststatus']
    assert_equal 9, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[1].attribute_map['codingdnasequencechange']
  end

  test 'process_nilstatus_record_nogene_nomutation_noscope' do
    nostatus_no_mutationrecord = build_raw_record('pseudo_id1' => 'bob')
    nostatus_no_mutationrecord.raw_fields['moleculartestingtype'] = 'Unknown / other'
    nostatus_no_mutationrecord.raw_fields['service category'] = 'B1'
    nostatus_no_mutationrecord.raw_fields['investigation code'] = 'BRCA'
    nostatus_no_mutationrecord.raw_fields['gene'] = ''
    nostatus_no_mutationrecord.raw_fields['genotype'] = ''
    nostatus_no_mutationrecord.raw_fields['variantpathclass'] = ''
    nostatus_no_mutationrecord.raw_fields['teststatus'] = ''
    nostatus_genotype = Import::Brca::Core::GenotypeBrca.new(nostatus_no_mutationrecord)
    @handler.process_test_scope(nostatus_genotype, nostatus_no_mutationrecord)
    @handler.process_test_status(nostatus_genotype, nostatus_no_mutationrecord)
    @handler.process_variant_records(nostatus_genotype, nostatus_no_mutationrecord)
    assert_equal 'Unable to assign BRCA genetictestscope', nostatus_genotype.attribute_map['genetictestscope']
    assert_equal 1, nostatus_genotype.attribute_map['teststatus']
    assert_nil nostatus_genotype.attribute_map['gene']
    assert_nil nostatus_genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_noscope_with_gene_mutation' do
    noscope_genemutation_record = build_raw_record('pseudo_id1' => 'bob')
    noscope_genemutation_record.raw_fields['moleculartestingtype'] = 'Unknown / other'
    noscope_genemutation_record.raw_fields['service category'] = 'B'
    noscope_genemutation_record.raw_fields['investigation code'] = 'BRCA'
    noscope_genemutation_record.raw_fields['gene'] = 'BRCA2'
    noscope_genemutation_record.raw_fields['genotype'] = 'c.8850G>T'
    noscope_genemutation_record.raw_fields['variantpathclass'] = 'non-pathological variant'
    noscope_genemutation_record.raw_fields['teststatus'] = 'het'
    noscope_genotype = Import::Brca::Core::GenotypeBrca.new(noscope_genemutation_record)
    @handler.process_test_scope(noscope_genotype, noscope_genemutation_record)
    @handler.process_test_status(noscope_genotype, noscope_genemutation_record)
    genotypes = @handler.process_variant_records(noscope_genotype, noscope_genemutation_record)
    assert_equal 'Unable to assign BRCA genetictestscope', noscope_genotype.attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_nmd_withmutation_record' do
    nmd_withmutation_record = build_raw_record('pseudo_id1' => 'bob')
    nmd_withmutation_record.raw_fields['moleculartestingtype'] = 'Diagnostic'
    nmd_withmutation_record.raw_fields['service category'] = 'O'
    nmd_withmutation_record.raw_fields['investigation code'] = 'BRCA1'
    nmd_withmutation_record.raw_fields['gene'] = 'BRCA1'
    nmd_withmutation_record.raw_fields['genotype'] = 'c.2315T>C (p.Val772Ala)'
    nmd_withmutation_record.raw_fields['variantpathclass'] = 'unclassified variant'
    nmd_withmutation_record.raw_fields['teststatus'] = 'nmd'
    nmd_withmutation_genotype = Import::Brca::Core::GenotypeBrca.new(nmd_withmutation_record)
    @handler.process_test_scope(nmd_withmutation_genotype, nmd_withmutation_record)
    @handler.process_test_status(nmd_withmutation_genotype, nmd_withmutation_record)
    genotypes = @handler.process_variant_records(nmd_withmutation_genotype, nmd_withmutation_record)
    assert_equal 'Full screen BRCA1 and BRCA2', nmd_withmutation_genotype.attribute_map['genetictestscope']
    assert_equal 2, nmd_withmutation_genotype.attribute_map['teststatus']
    assert_equal 7, nmd_withmutation_genotype.attribute_map['gene']
    assert_equal 'c.2315T>C', nmd_withmutation_genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Val772Ala', nmd_withmutation_genotype.attribute_map['proteinimpact']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
  end

  test 'process_non_brca_gene' do
    non_brca_gene_record = build_raw_record('pseudo_id1' => 'bob')
    non_brca_gene_record.raw_fields['moleculartestingtype'] = 'Storage'
    non_brca_gene_record.raw_fields['service category'] = 'O'
    non_brca_gene_record.raw_fields['investigation code'] = 'BRCA'
    non_brca_gene_record.raw_fields['gene'] = 'PALB2'
    non_brca_gene_record.raw_fields['genotype'] = 'c.3048del p.(Phe1016fs)'
    non_brca_gene_record.raw_fields['variantpathclass'] = 'Pathogenic'
    non_brca_gene_record.raw_fields['teststatus'] = 'het'
    non_brca_genotype = Import::Brca::Core::GenotypeBrca.new(non_brca_gene_record)
    @handler.process_test_scope(non_brca_genotype, non_brca_gene_record)
    @handler.process_test_status(non_brca_genotype, non_brca_gene_record)
    genotypes = @handler.process_variant_records(non_brca_genotype, non_brca_gene_record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 3, genotypes.size
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_equal 2, genotypes[2].attribute_map['teststatus']
    assert_equal 3186, genotypes[2].attribute_map['gene']
    assert_equal 'c.3048del', genotypes[2].attribute_map['codingdnasequencechange']
    assert_equal 'p.Phe1016fs', genotypes[2].attribute_map['proteinimpact']
  end

  test 'process_het_fs_record' do
    het_fs_record = build_raw_record('pseudo_id1' => 'bob')
    het_fs_record.raw_fields['moleculartestingtype'] = 'Storage'
    het_fs_record.raw_fields['service category'] = 'C'
    het_fs_record.raw_fields['investigation code'] = 'BRCA'
    het_fs_record.raw_fields['gene'] = ''
    het_fs_record.raw_fields['genotype'] = ''
    het_fs_record.raw_fields['variantpathclass'] = ''
    het_fs_record.raw_fields['teststatus'] = 'het'
    het_fs_genotype = Import::Brca::Core::GenotypeBrca.new(het_fs_record)
    @handler.process_test_scope(het_fs_genotype, het_fs_record)
    @handler.process_test_status(het_fs_genotype, het_fs_record)
    genotypes = @handler.process_variant_records(het_fs_genotype, het_fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 2, genotypes.size
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
  end

  test 'process_fs_rec_with_gene_nomutation' do
    nmd_withmutation_record = build_raw_record('pseudo_id1' => 'bob')
    nmd_withmutation_record.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    nmd_withmutation_record.raw_fields['service category'] = 'O'
    nmd_withmutation_record.raw_fields['investigation code'] = 'BRCA'
    nmd_withmutation_record.raw_fields['gene'] = 'BRCA1'
    nmd_withmutation_record.raw_fields['genotype'] = ''
    nmd_withmutation_record.raw_fields['variantpathclass'] = 'unclassified variant'
    nmd_withmutation_record.raw_fields['teststatus'] = 'variant'
    nmd_withmutation_genotype = Import::Brca::Core::GenotypeBrca.new(nmd_withmutation_record)
    @handler.process_test_scope(nmd_withmutation_genotype, nmd_withmutation_record)
    @handler.process_test_status(nmd_withmutation_genotype, nmd_withmutation_record)
    genotypes = @handler.process_variant_records(nmd_withmutation_genotype, nmd_withmutation_record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 4, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[1].attribute_map['proteinimpact']
  end

  test 'process_fs_rec_only_with_no_result_status' do
    no_result_fs_record = build_raw_record('pseudo_id1' => 'bob')
    no_result_fs_record.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    no_result_fs_record.raw_fields['service category'] = 'B'
    no_result_fs_record.raw_fields['investigation code'] = 'BRCA'
    no_result_fs_record.raw_fields['gene'] = nil
    no_result_fs_record.raw_fields['genotype'] = nil
    no_result_fs_record.raw_fields['variantpathclass'] = nil
    no_result_fs_record.raw_fields['teststatus'] = 'no-result'
    no_result_fs_genotype = Import::Brca::Core::GenotypeBrca.new(no_result_fs_record)
    @handler.process_test_scope(no_result_fs_genotype, no_result_fs_record)
    @handler.process_test_status(no_result_fs_genotype, no_result_fs_record)
    genotypes = @handler.process_variant_records(no_result_fs_genotype, no_result_fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil no_result_fs_genotype.attribute_map['codingdnasequencechange']
    assert_nil no_result_fs_genotype.attribute_map['proteinimpact']
  end

  test 'process_fs_rec_only_with_completed_status' do
    completed_fs_record = build_raw_record('pseudo_id1' => 'bob')
    completed_fs_record.raw_fields['moleculartestingtype'] = 'Diagnostic'
    completed_fs_record.raw_fields['service category'] = 'O'
    completed_fs_record.raw_fields['investigation code'] = 'BRCA'
    completed_fs_record.raw_fields['gene'] = nil
    completed_fs_record.raw_fields['genotype'] = nil
    completed_fs_record.raw_fields['variantpathclass'] = nil
    completed_fs_record.raw_fields['teststatus'] = 'completed'
    completed_fs_genotype = Import::Brca::Core::GenotypeBrca.new(completed_fs_record)
    @handler.process_test_scope(completed_fs_genotype, completed_fs_record)
    @handler.process_test_status(completed_fs_genotype, completed_fs_record)
    genotypes = @handler.process_variant_records(completed_fs_genotype, completed_fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, completed_fs_genotype.attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 8, genotypes[1].attribute_map['gene']
    assert_nil completed_fs_genotype.attribute_map['codingdnasequencechange']
    assert_nil completed_fs_genotype.attribute_map['proteinimpact']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
  end

  test 'process_targ_rec_with_gene_low_status' do
    low_gene_targ_rec = build_raw_record('pseudo_id1' => 'bob')
    low_gene_targ_rec.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    low_gene_targ_rec.raw_fields['service category'] = 'B'
    low_gene_targ_rec.raw_fields['investigation code'] = 'BRCA2'
    low_gene_targ_rec.raw_fields['gene'] = nil
    low_gene_targ_rec.raw_fields['genotype'] = nil
    low_gene_targ_rec.raw_fields['variantpathclass'] = nil
    low_gene_targ_rec.raw_fields['teststatus'] = 'low'
    low_gene_genotype = Import::Brca::Core::GenotypeBrca.new(low_gene_targ_rec)
    @handler.process_test_scope(low_gene_genotype, low_gene_targ_rec)
    assert_equal 'Targeted BRCA mutation test', low_gene_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(low_gene_genotype, low_gene_targ_rec)
    genotypes = @handler.process_variant_records(low_gene_genotype, low_gene_targ_rec)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_targ_all_nils' do
    all_nils_targ_rec = build_raw_record('pseudo_id1' => 'bob')
    all_nils_targ_rec.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    all_nils_targ_rec.raw_fields['service category'] = 'B'
    all_nils_targ_rec.raw_fields['investigation code'] = 'BRCA1'
    all_nils_targ_rec.raw_fields['gene'] = nil
    all_nils_targ_rec.raw_fields['genotype'] = nil
    all_nils_targ_rec.raw_fields['variantpathclass'] = nil
    all_nils_targ_rec.raw_fields['teststatus'] = nil
    all_nils_genotype = Import::Brca::Core::GenotypeBrca.new(all_nils_targ_rec)
    @handler.process_test_scope(all_nils_genotype, all_nils_targ_rec)
    assert_equal 'Targeted BRCA mutation test', all_nils_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(all_nils_genotype, all_nils_targ_rec)
    genotypes = @handler.process_variant_records(all_nils_genotype, all_nils_targ_rec)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_nil all_nils_genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_targ_rec_with_gene_verify_status' do
    verify_gene_targ_rec = build_raw_record('pseudo_id1' => 'bob')
    verify_gene_targ_rec.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    verify_gene_targ_rec.raw_fields['service category'] = 'B'
    verify_gene_targ_rec.raw_fields['investigation code'] = 'BRCA2'
    verify_gene_targ_rec.raw_fields['gene'] = nil
    verify_gene_targ_rec.raw_fields['genotype'] = nil
    verify_gene_targ_rec.raw_fields['variantpathclass'] = nil
    verify_gene_targ_rec.raw_fields['teststatus'] = 'verify'
    verify_gene_genotype = Import::Brca::Core::GenotypeBrca.new(verify_gene_targ_rec)
    @handler.process_test_scope(verify_gene_genotype, verify_gene_targ_rec)
    assert_equal 'Targeted BRCA mutation test', verify_gene_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(verify_gene_genotype, verify_gene_targ_rec)
    genotypes = @handler.process_variant_records(verify_gene_genotype, verify_gene_targ_rec)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_targ_rec_with_gene_no_result_status' do
    no_result_gene_targ_rec = build_raw_record('pseudo_id1' => 'bob')
    no_result_gene_targ_rec.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    no_result_gene_targ_rec.raw_fields['service category'] = 'B'
    no_result_gene_targ_rec.raw_fields['investigation code'] = 'BRCA2'
    no_result_gene_targ_rec.raw_fields['gene'] = nil
    no_result_gene_targ_rec.raw_fields['genotype'] = nil
    no_result_gene_targ_rec.raw_fields['variantpathclass'] = nil
    no_result_gene_targ_rec.raw_fields['teststatus'] = 'no-result'
    no_result_gene_genotype = Import::Brca::Core::GenotypeBrca.new(no_result_gene_targ_rec)
    @handler.process_test_status(no_result_gene_genotype, no_result_gene_targ_rec)
    @handler.process_test_scope(no_result_gene_genotype, no_result_gene_targ_rec)
    assert_equal 'Targeted BRCA mutation test', no_result_gene_genotype.attribute_map['genetictestscope']
    genotypes = @handler.process_variant_records(no_result_gene_genotype, no_result_gene_targ_rec)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  test 'process_targ_rec_with_nilgene_completed_status' do
    verify_nilgene_targ_rec = build_raw_record('pseudo_id1' => 'bob')
    verify_nilgene_targ_rec.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    verify_nilgene_targ_rec.raw_fields['service category'] = 'B'
    verify_nilgene_targ_rec.raw_fields['investigation code'] = 'BRCA'
    verify_nilgene_targ_rec.raw_fields['gene'] = nil
    verify_nilgene_targ_rec.raw_fields['genotype'] = nil
    verify_nilgene_targ_rec.raw_fields['variantpathclass'] = nil
    verify_nilgene_targ_rec.raw_fields['teststatus'] = 'completed'
    verify_nilgene_genotype = Import::Brca::Core::GenotypeBrca.new(verify_nilgene_targ_rec)
    @handler.process_test_scope(verify_nilgene_genotype, verify_nilgene_targ_rec)
    assert_equal 'Targeted BRCA mutation test', verify_nilgene_genotype.attribute_map['genetictestscope']
    @handler.process_test_status(verify_nilgene_genotype, verify_nilgene_targ_rec)
    genotypes = @handler.process_variant_records(verify_nilgene_genotype, verify_nilgene_targ_rec)
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['gene']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
  end

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_clinical_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2006-10-13T00: 00: 00.000+01: 00',
      authoriseddate: '2007-01-02T00: 00: 00.000+00: 00',
      sortdate: '2006-10-13T00: 00: 00.000+01: 00',
      specimentype: '5',
      gene: '7',
      variantpathclass: 'unclassified variant',
      requesteddate: '2006-10-27T00: 00: 00.000+01: 00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Servire Report Identifier',
      'service category' => 'O',
      moleculartestingtype: 'Diagnostic',
      'investigation code' => 'BRCA',
      gene: 'BRCA1',
      genotype: 'c.2597G>A',
      variantpathclass: 'unclassified variant',
      teststatus: 'other',
      specimentype: 'Blood',
      receiveddate: '2006-10-13 00: 00: 00',
      requesteddate: '2006-10-27 00: 00: 00',
      authoriseddate: '2007-01-02 00: 00: 00' }.to_json
  end
end
