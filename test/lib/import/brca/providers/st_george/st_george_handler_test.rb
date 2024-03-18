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

    #Test when variant dna column contains fail
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'All genes have Failed'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 9, @genotype.attribute_map['teststatus']

    #Test when variant dna column contains N
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #Test when [raw:gene is not null] AND [raw:gene (other) is null] and gene in question is in gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'value'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene(other)'] = nil
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['BRCA1'], 'gene(other)':[], 'variant dna': ['BRCA1']}, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']


    #Test when [raw:gene is not null] AND [raw:gene (other) is null] and gene in question is not in gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'value'
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene(other)'] = nil
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['BRCA1'], 'gene(other)':[], 'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #[Is not '*Fail*', 'N' or null] AND [raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'CHECK2', {'gene': ['CHECK2'], 'gene(other)':['BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    #[raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene(other) column but not failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']


    #[raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene(other) column and has failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    #[raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene(other) column and has failed (BRCA1/2)
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    #[raw:gene is not null] AND [raw:gene (other) is not null] and gene in question is in gene(other) column and has failed(BRCA1/2)
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = 'CHECK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['CHECK2'], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

 

    #Test when raw:gene is null] AND raw:gene (other) specifies a single gene and the gene in question is in the gene(other column)
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': [], 'gene(other)':['BRCA1'], 'variant dna': ['BRCA2']}, @genotype, 'gene(other)')
    assert_equal 2, @genotype.attribute_map['teststatus']

    #Test when raw:gene is null] AND raw:gene (other) specifies a single gene and the gene in question is not in  the gene(other) column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'ATM'
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': [], 'gene(other)':['BRCA1'], 'variant dna': ['ATM'], 'test/panel': 'BRCA2'}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']


    #Test when raw:gene is null] AND raw:gene (other) does not specify a single gene, and gene in question is in the variant dna column

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHEK2'], 'gene(other)':[ 'BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'variant dna')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #Test when raw:gene is null] AND raw:gene (other) does not specify a single gene, and gene in question is not in variant dna column but there is a gene in variant dna column

    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = ''
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['BRCA1', 'BRCA2'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']


    #tests when there is a fail in gene(other) column, and the gene in question has failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': [], 'gene(other)':['BRCA1', 'BRCA2'], 'variant dna': []}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

      #tests when there is a fail and more than one gene in gene(other) column, and the gene in question has not failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'ATM BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': [], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': []}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #tests when there is a fail in gene(other) column and there is more than one gene ,and the gene in question has failed
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'ATM BRCA1/2 FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, 'gene(other)')
    assert_equal 9, @genotype.attribute_map['teststatus']

    #test when there is fail in gene(other) column with no gene specified and there is gene listed in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA2'
    full_screen_test_status.raw_fields['gene(other)'] = 'FAIL'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': ['BRCA2'], 'gene(other)':['FAIL'], 'variant dna': []}, @genotype, 'gene')
    assert_equal 10, @genotype.attribute_map['teststatus']

    #test when there is fail in gene(other) column with no gene specified and the gene is not listed in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'FAIL'
    full_screen_test_status.raw_fields['test/panel'] = 'BRCA2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA2', {'gene': [], 'gene(other)':['FAIL'], 'variant dna': [], 'test/panel': ['BRCA2']}, @genotype, 'test/panel')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #test when the regex matches the gene(other) column and the gene is in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'BRCA1'
    full_screen_test_status.raw_fields['gene(other)'] = 'c.1234'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA2'], 'variant dna': []}, @genotype, 'gene')
    assert_equal 2, @genotype.attribute_map['teststatus']

    #test when the regex matches the gene(other) column and the gene is not in the gene column
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = 'CHEK2'
    full_screen_test_status.raw_fields['gene(other)'] = 'c.1234 ATM BRCA1/2'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHEK2'], 'gene(other)':['ATM', 'BRCA2', 'BRCA1'], 'variant dna': []}, @genotype, 'gene(other)')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #test when the value in gene(other) is in the format 'gene Class V, gene N' - first gene
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'ATM', {'gene': ['CHEK2'], 'gene(other)':['ATM', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 1, @genotype.attribute_map['teststatus']

    #test when the value in gene(other) is in the format 'gene Class V, gene N' - second gene
    full_screen_test_status = build_raw_record('pseudo_id1' => 'bob')
    full_screen_test_status.raw_fields['variant dna'] = nil
    full_screen_test_status.raw_fields['gene'] = nil
    full_screen_test_status.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.assign_test_status_full_screen(full_screen_test_status, 'BRCA1', {'gene': ['CHECK2'], 'gene(other)':['ATM', 'BRCA1'], 'variant dna': ['BRCA1']}, @genotype, '')
    assert_equal 2, @genotype.attribute_map['teststatus']

    # test assigning test status of 4 when none of the scenarios above fit
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
    genes= @handler.process_genes_targeted(targeted)
    assert_equal [['BRCA1']], genes

  end


  test 'handle_test_status_full_screen' do

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.handle_test_status_full_screen(targeted, @genotype, {"gene"=> ["BRCA1"], "gene(other)"=> [], "variant dna"=> [], "test/panel"=>[] })
    assert_equal 7, @genotype.attribute_map['gene']

    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    @handler.handle_test_status_full_screen(targeted, @genotype, {"gene"=>["BRCA1"], "gene(other)"=>[]})
    assert_equal 7, @genotype.attribute_map['gene']


  end


  test 'process_genes_full_screen' do
    targeted = build_raw_record('pseudo_id1' => 'bob')
    targeted.raw_fields['gene']="BRCA1"
    targeted.raw_fields['gene(other)']="unknown"
    genes_dict=@handler.process_genes_full_screen(@genotype, targeted)
    #TODO fix this test
    assert_equal '{"gene"=>["BRCA1"], "gene(other)"=>[]}', genes_dict
  end

  test 'process_variants' do

    process_variants1 = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus']= 2
    process_variants1.raw_fields['variant dna']='c.1234A<G'
    process_variants1.raw_fields['variant protein']='p.1234Arg123Gly'
    @handler.process_variants(@genotype, process_variants1)
    assert_equal "c.1234A<G", @genotype.attribute_map['codingdnasequencechange']
    assert_equal "p.1234Arg123Gly", @genotype.attribute_map['proteinimpact']

    process_variants2 = build_raw_record('pseudo_id1' => 'bob')
    @genotype.attribute_map['teststatus']= 2
    process_variants2.raw_fields['variant dna']='het del ex 12-34'
    process_variants2.raw_fields['variant proteins']=''
    @handler.process_variants(@genotype, process_variants2)
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
    assert_equal "12-34", @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 1, @genotype.attribute_map['variantgenotype']

  end
  
  test 'gene_classv_gene_n_format' do
    #test, when 'gene(other)' column has following format 'GENE1 Class V, GENE2 N' that the second gene gets teststatus 2 assigned 
    gene_classv_gene_n = build_raw_record('pseudo_id1' => 'bob')
    gene_classv_gene_n.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.gene_classv_gene_n_format(gene_classv_gene_n, @genotype, 'ATM',)
    assert_equal 1, @genotype.attribute_map['teststatus']

   #test, when 'gene(other)' column has following format 'GENE1 Class V, GENE2 N' that the first gene gets teststatus 1 assigned
    gene_classv_gene_n = build_raw_record('pseudo_id1' => 'bob')
    gene_classv_gene_n.raw_fields['gene(other)'] = 'BRCA1 Class V, ATM N'
    @handler.gene_classv_gene_n_format(gene_classv_gene_n, @genotype, 'BRCA1')
    assert_equal 2, @genotype.attribute_map['teststatus']


  end 

  def clinical_json
    +
    {}.to_json
  end

  def rawtext_clinical_json
    { }.to_json
  end


end



