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

=begin
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
    targeted.raw_fields['gene (other)'] = 'blank contamination'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'het 123'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene (other)'] = 'c.123'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    #Priority 2
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'Fail'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'Blank contamination'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 9, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'Normal'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 1, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'no del/dup'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 1, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'SNP present'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 4, @genotype.attribute_map['teststatus']

    #TODO error in priority order - works with changes
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'see comments het del'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 4, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'het del'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = 'del ex'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']

    #Priority 3
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene'] = ''
    targeted.raw_fields['gene(other)'] = ''
    targeted.raw_fields['variant dna'] = ''
    targeted.raw_fields['variant protein'] = 'p.123'
    @handler.assign_test_status_targeted(@genotype, targeted)
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

=end


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


  test 'assign_test_status_full_screen' do
    fs_variant_dna_column = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_column.raw_fields['gene'] = 'BRCA1'
    fs_variant_dna_column.raw_fields['variant dna'] = 'Fail'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_column, @genotype, { 'gene' => ['BRCA1'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []}, 'gene', 'BRCA1' )
    assert_equal 9, @genotype.attribute_map['teststatus']

    fs_variant_dna_column = build_raw_record('pseudo_id1' => 'bob')
    fs_variant_dna_column.raw_fields['gene'] = 'BRCA1'
    fs_variant_dna_column.raw_fields['variant dna'] = 'N'
    genotypes = @handler.assign_test_status_fullscreen(fs_variant_dna_column, @genotype, { 'gene' => ['BRCA1'], 'gene (other)' => [], 'variant dna' => [], 'test/panel' => []}, 'gene', 'BRCA1' )
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  def clinical_json
    +
    {}.to_json
  end

  def rawtext_clinical_json
    {}.to_json
  end
end