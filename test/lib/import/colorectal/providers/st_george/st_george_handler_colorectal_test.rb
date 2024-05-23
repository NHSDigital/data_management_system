require 'test_helper'

class StGeorgeTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::StGeorge::StGeorgeHandlerColorectal.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end


  test 'assign_test_type' do

    carrier_record1 = build_raw_record('pseudo_id1' => 'bob')
    carrier_record1.raw_fields['moleculartestingtype'] = 'Carrier testing for known familial mutation(s)'
    @handler.assign_test_type(@genotype, carrier_record1)
    assert_equal 3, @genotype.attribute_map['moleculartestingtype']

    #TODO check this mapping
    diagnostic_record1 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record1.raw_fields['moleculartestingtype'] = 'Inherited colorectal cancer (with or without polyposis)'
    @handler.assign_test_type(@genotype, diagnostic_record1)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record2 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record2.raw_fields['moleculartestingtype'] = 'Inherited MMR deficiency (Lynch syndrome)'
    @handler.assign_test_type(@genotype, diagnostic_record2)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record3 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record3.raw_fields['moleculartestingtype'] = 'Inherited polyposis - germline test'
    @handler.assign_test_type(@genotype, diagnostic_record3)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record4 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record4.raw_fields['moleculartestingtype'] = 'APC associated Polyposis'
    @handler.assign_test_type(@genotype, diagnostic_record4)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record5 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record5.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    @handler.assign_test_type(@genotype, diagnostic_record5)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    diagnostic_record6 = build_raw_record('pseudo_id1' => 'bob')
    diagnostic_record6.raw_fields['moleculartestingtype'] = 'Family follow-up testing to aid variant interpretation'
    @handler.assign_test_type(@genotype, diagnostic_record6)
    assert_equal 1, @genotype.attribute_map['moleculartestingtype']

    predictive_record1 = build_raw_record('pseudo_id1' => 'bob')
    predictive_record1.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    @handler.assign_test_type(@genotype, predictive_record1)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']

  end

  test 'assign_test_scope' do
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


test 'fill_genotypes' do
end 

test 'process_genes' do 
#test where it is not a panel

mhs6_typo=build_raw_record('pseudo_id1' => 'bob')
mhs6_typo.raw_fields['gene'] = 'MHS2'
mhs6_typo.raw_fields['gene (other)'] = 'unknown'
genes_dict= @handler.process_genes(mhs6_typo)
assert_equal ({ 'gene' => %w[MSH2], 'gene (other)' => [] }), genes_dict

targeted_crc=build_raw_record('pseudo_id1' => 'bob')
targeted_crc.raw_fields['gene'] = 'MLH1'
targeted_crc.raw_fields['gene (other)'] = 'MSH6'
genes_dict= @handler.process_genes(targeted_crc)
assert_equal ({ 'gene' => %w[MLH1], 'gene (other)' => ['MSH6'] }), genes_dict

fs_crc=build_raw_record('pseudo_id1' => 'bob')
fs_crc.raw_fields['gene'] = ''
fs_crc.raw_fields['gene (other)'] = 'MLH1, MSH2, MSH6, EPCAM'
genes_dict= @handler.process_genes(fs_crc)
assert_equal ({ 'gene' => %w[], 'gene (other)' => ['MLH1', 'MSH2', 'MSH6', 'EPCAM'] }), genes_dict



end 

test 'process_test_panels' do

  r209 = build_raw_record('pseudo_id1' => 'bob')
  r209.raw_fields['test/panel'] = 'R209'
  genes= @handler.process_test_panels(r209, [], 'test/panel')
  assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11], genes

  lynch = build_raw_record('pseudo_id1' => 'bob')
  lynch.raw_fields['test/panel'] = 'Lynch (R210)'
  genes= @handler.process_test_panels(lynch, [], 'test/panel')
  assert_equal %w[EPCAM MLH1 MSH2 MSH6 PMS2], genes

  r414 = build_raw_record('pseudo_id1' => 'bob')
  r414.raw_fields['test/panel'] = 'R414'
  genes= @handler.process_test_panels(r414, [], 'test/panel')
  assert_equal %w[APC], genes

end




  test 'process_r211' do

    r211_before = build_raw_record('pseudo_id1' => 'bob')
    r211_before.raw_fields['test/panel'] = 'R211'
    r211_before.raw_fields['authoriseddate']='17/07/2022'
    genes= @handler.process_r211(r211_before)
    assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11], genes

    r211_after = build_raw_record('pseudo_id1' => 'bob')
    r211_after.raw_fields['test/panel'] = 'R211'
    r211_after.raw_fields['authoriseddate']='18/07/2022'
    genes= @handler.process_r211(r211_after)
    assert_equal %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11 GREM1 RNF43], genes
  end

  test 'handle_test_status' do 

    #how to give it the genetictestscope variable so it knows which to follow in the if/else loop 
    #- not sure how to test this method, ideally need to test the duplication part.

    # fs_gene_column = build_raw_record('pseudo_id1' => 'bob')
    # fs_gene_column.raw_fields['gene'] = 'MSH2'
    # fs_gene_column.raw_fields['gene (other)'] = 'unknown'

    # genotypes = @handler.handle_test_status(fs_gene_column, @genotype, { 'gene' => ['MSH2'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => [] })
    # assert_equal 2804, @genotype.attribute_map['gene']
    # assert_equal 1, genotypes.length

    # fs_geneother_column = build_raw_record('pseudo_id1' => 'bob')
    # fs_geneother_column.raw_fields['gene'] = 'unknown'
    # fs_geneother_column.raw_fields['gene (other)'] = 'MSH2'
    # genotypes = @handler.handle_test_status(fs_geneother_column, @genotype, { 'gene' => [], 'gene (other)' => ['MSH2'], 'variant dna' => [], 'test/panel' => [] })
    # assert_equal 2804, @genotype.attribute_map['gene ']
    # assert_equal 1, genotypes.length


  end


  test 'assign_test_status_full_screen' do
    fs_variant_dna_fail = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_fail.raw_fields['gene'] = 'APC'
    fs_variant_dna_fail.raw_fields['variant dna'] = 'Fail'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_fail, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []},  'gene' , 'APC' )
    assert_equal 9, @genotype.attribute_map['teststatus']

    fs_variant_dna_N = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_N.raw_fields['gene'] = 'APC'
    fs_variant_dna_N.raw_fields['variant dna'] = 'N'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_N, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []},'gene' ,'APC'  )
    assert_equal 1, @genotype.attribute_map['teststatus']

    fs_variant_dna_c = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_c.raw_fields['gene'] = 'APC'
    fs_variant_dna_c.raw_fields['variant dna'] = 'c.3920T>A'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_c,  @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []}, 'gene','APC' )
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_dna_gene_null = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_gene_null.raw_fields['gene'] = nil
    fs_variant_dna_gene_null.raw_fields['gene (other)'] = 'APC'
    fs_variant_dna_gene_null.raw_fields['variant dna'] = 'c.3920T>A'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_gene_null,  @genotype, { 'gene' => [], 'gene (other)' => ['APC'], 'variant dna' => [], 'test/panel' => []}, 'gene (other)','APC' )
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_dna_gene_null = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_gene_null.raw_fields['gene'] = nil
    fs_variant_dna_gene_null.raw_fields['gene (other)'] = 'APC, BMPR1A, EPCAM, MLH1, MSH2, MSH6, MUTYH, NTHL1'
    fs_variant_dna_gene_null.raw_fields['variant dna'] = 'c.3920T>A'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_gene_null,  @genotype, { 'gene' => [], 'gene (other)' => ['APC, BMPR1A, EPCAM, MLH1, MSH2, MSH6, MUTYH, NTHL1'], 'variant dna' => [], 'test/panel' => []}, 'gene (other)','APC' )
    assert_equal 2, @genotype.attribute_map['teststatus']

    fs_variant_protein_null = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_protein_null.raw_fields['variant protein'] = 'Fail'
    fs_variant_protein_null.raw_fields['gene'] = 'APC'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_protein_null,  @genotype, { 'gene' => [], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []}, 'gene','APC' )
    assert_equal 9, @genotype.attribute_map['teststatus']

    fs_variant_protein_p = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_protein_p.raw_fields['variant protein'] = 'p.(Thr328Ter)'
    fs_variant_protein_p.raw_fields['gene'] = 'APC'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_protein_p,  @genotype, { 'gene' => [], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []}, 'gene','APC' )
    assert_equal 2, @genotype.attribute_map['teststatus']
  end


  test 'assign_test_status_targeted' do
    fs_variant_dna_fail = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_fail.raw_fields['gene'] = 'APC'
    fs_variant_dna_fail.raw_fields['gene (other)'] = 'Fail'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_fail, @genotype, { 'gene' => ['APC'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []},  'gene' , 'APC' )
    assert_equal 9, @genotype.attribute_map['teststatus']  
  end 

  def clinical_json
    +
    {}.to_json
  end

  def rawtext_clinical_json
    {}.to_json
  end
end