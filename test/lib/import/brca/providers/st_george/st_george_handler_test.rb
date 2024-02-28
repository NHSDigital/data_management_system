require 'test_helper'

class StGeorgeTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::StGeorge::StGeorgeHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
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

  end

  test 'assign_test_scope' do
    targeted_record1 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record1.raw_fields['moleculartestingtype'] = 'Diagnostic testing for known mutation(s)'
    targeted_record1.raw_fields['gene(other)'] = 'N'
    targeted_record1.raw_fields['variant dna'] = ''
    targeted_record1.raw_fields['variant protein'] = ''
    @handler.assign_test_scope(@genotype, targeted_record1)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']


    targeted_record2 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record2.raw_fields['moleculartestingtype'] = 'Family follow-up testing to aid variant interpretation'
    targeted_record2.raw_fields['gene(other)'] = 'N'
    targeted_record2.raw_fields['variant dna'] = ''
    targeted_record2.raw_fields['variant protein'] = ''
    @handler.assign_test_scope(@genotype, targeted_record2)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    targeted_record3 = build_raw_record('pseudo_id1' => 'bob')
    targeted_record3.raw_fields['moleculartestingtype'] = 'Inherited breast cancer and ovarian cancer'
    targeted_record3.raw_fields['gene(other)'] = 'N'
    targeted_record3.raw_fields['variant dna'] = ''
    targeted_record3.raw_fields['variant protein'] = ''
    @handler.assign_test_scope(@genotype, targeted_record3)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    fullscreen_record1 = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_record1.raw_fields['moleculartestingtype'] = 'Inherited ovarian cancer (without breast cancer)'
    fullscreen_record1.raw_fields['gene(other)'] = 'N'
    fullscreen_record1.raw_fields['variant dna'] = ''
    fullscreen_record1.raw_fields['variant protein'] = ''
    @handler.assign_test_scope(@genotype, fullscreen_record1)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    fullscreen_record2 = build_raw_record('pseudo_id1' => 'bob')
    fullscreen_record2.raw_fields['moleculartestingtype'] = 'Predictive testing for known familial mutation(s)'
    fullscreen_record2.raw_fields['gene(other)'] = 'N'
    fullscreen_record2.raw_fields['variant dna'] = ''
    fullscreen_record2.raw_fields['variant protein'] = ''
    @handler.assign_test_scope(@genotype, fullscreen_record2)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

  end


  test 'assign_test_status_full_screen' do

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'All genes have Failed'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 9, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']


    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'value'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene(other)'] = nil
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['BRCA1'], 'gene(other)':[], 'variant dna': ['BRCA1']}, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'value'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene(other)'] = nil
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['BRCA1'], 'gene(other)':[], 'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #[Is not '*Fail*', 'N' or null] AND [raw:gene is not null] AND [raw:gene (other) is not null]
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'CHECK2', {'gene': ['CHECK2'], 'gene(other)':['BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']



    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1', 'BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1', 'BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'ATM BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'ATM BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene')
    assert_equal 10, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 1, @genotype.attribute_map['teststatus']


    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'c.1234 ATM BRCA1/2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'c.1234 ATM BRCA1/2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 1, @genotype.attribute_map['teststatus']


    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 1, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 2, @genotype.attribute_map['teststatus']

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'unknown'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 4, @genotype.attribute_map['teststatus']

  end



  test 'process_r208' do
    r208_first_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_first_panel.raw_fields['test/panel'] = 'R208'
    r208_first_panel.raw_fields['authoriseddate'] = '09/07/2022'
    genes=@handler.process_r208(@genotype, r208_first_panel, [])
    assert_equal ['BRCA1', 'BRCA2'], genes

    r208_second_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_second_panel.raw_fields['test/panel'] = 'R208'
    r208_second_panel.raw_fields['authoriseddate'] = '01/08/2022'
    genes=@handler.process_r208(@genotype, r208_second_panel, [])
    assert_equal ['BRCA1', 'BRCA2', 'CHEK2', 'PALB2', 'ATM'], genes

    r208_third_panel = build_raw_record('pseudo_id1' => 'bob')
    r208_third_panel.raw_fields['test/panel'] = 'R208'
    r208_third_panel.raw_fields['authoriseddate'] = '01/01/2023'
    genes=@handler.process_r208(@genotype, r208_third_panel, [])
    assert_equal [ 'BRCA1', 'BRCA2', 'CHEK2', 'PALB2', 'ATM', 'RAD51C', 'RAD51D'], genes


  end

  test 'process_genes_targeted' do
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.process_genes_targeted(@genotype, targeted)
    assert_equal 7, @genotype.attribute_map['gene']

  end

=begin
  test 'handle_test_status_full_screen' do
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.handle_test_status_full_screen(targeted, @genotype, {'gene': ["BRCA1"], 'gene(other)': [], 'variant dna': [], 'test/panel':[] })
    assert_equal 7, @genotype.attribute_map['gene']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.handle_test_status_full_screen(targeted, @genotype, {"gene"=>["BRCA1"], "gene(other)"=>[]})
    assert_equal 7, @genotype.attribute_map['gene']
  end
=end

  test 'process_genes_full_screen' do
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.process_genes_full_screen(@genotype, targeted)
    assert_equal 7, @genotype.attribute_map['gene']
  end

  test 'process_variants' do

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.mapped_fields['teststatus']= 2
    targeted.raw_fields['variant dna']='c.1234A<G'
    targeted.raw_fields['variant protein']='p.1234Arg123Gly'
    @handler.process_variants(@genotype, targeted)
    assert_equal "c.1234A<G", @genotype.attribute_map['codingdnasequencechange']
    assert_equal "p.1234Arg123Gly", @genotype.attribute_map['proteinimpact']

  end


  def clinical_json
    {}.to_json
  end

  def rawtext_clinical_json
    { }.to_json
  end


end



