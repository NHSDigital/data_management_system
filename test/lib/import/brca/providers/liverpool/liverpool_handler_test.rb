require 'test_helper'

class LiverpoolHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Liverpool::LiverpoolHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestscope' do
    targ_record = build_raw_record('pseudo_id1' => 'bob')
    @handler.add_genetictestscope(@genotype, targ_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    ashkenazi_record = build_raw_record('pseudo_id1' => 'bob')
    ashkenazi_record.raw_fields['testscope'] = 'Targeted mutation panel'
    @genotype = Import::Brca::Core::GenotypeBrca.new(ashkenazi_record)
    @handler.add_genetictestscope(@genotype, ashkenazi_record)
    assert_equal 'AJ BRCA screen', @genotype.attribute_map['genetictestscope']

    fs_record = build_raw_record('pseudo_id1' => 'bob')
    fs_record.raw_fields['testscope'] = 'Partial gene screen'
    @genotype = Import::Brca::Core::GenotypeBrca.new(fs_record)
    @handler.add_genetictestscope(@genotype, fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    partial_gene_mutation_screen_record = build_raw_record('pseudo_id1' => 'bob')
    partial_gene_mutation_screen_record.raw_fields['testscope'] = 'Partial gene mutation screen'
    @genotype = Import::Brca::Core::GenotypeBrca.new(partial_gene_mutation_screen_record)
    @handler.add_genetictestscope(@genotype, partial_gene_mutation_screen_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    sanger_mlpa_record = build_raw_record('pseudo_id1' => 'bob')
    sanger_mlpa_record.raw_fields['testscope'] = 'Sanger Sequence analysis and MLPA screen'
    @genotype = Import::Brca::Core::GenotypeBrca.new(sanger_mlpa_record)
    @handler.add_genetictestscope(@genotype, sanger_mlpa_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']

    mlpa_record = build_raw_record('pseudo_id1' => 'bob')
    mlpa_record.raw_fields['testscope'] = 'targeted mutation analysis - mlpa'
    @genotype = Import::Brca::Core::GenotypeBrca.new(mlpa_record)
    @handler.add_genetictestscope(@genotype, mlpa_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    sanger_record = build_raw_record('pseudo_id1' => 'bob')
    sanger_mlpa_record.raw_fields['testscope'] = 'targeted mutation analysis - sanger sequencing'
    @genotype = Import::Brca::Core::GenotypeBrca.new(sanger_record)
    @handler.add_genetictestscope(@genotype, sanger_record)
    assert_equal 'Targeted BRCA mutation test', @genotype.attribute_map['genetictestscope']

    no_scope_record = build_raw_record('pseudo_id1' => 'bob')
    no_scope_record.raw_fields['testscope'] = 'XYZ'
    @genotype = Import::Brca::Core::GenotypeBrca.new(no_scope_record)
    @handler.add_genetictestscope(@genotype, no_scope_record)
    assert_equal 'Unable to assign BRCA genetictestscope', @genotype.attribute_map['genetictestscope']
  end

  test 'process_teststatus' do
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['testresult'] = 'No variants detected'
    @handler.add_test_status(@genotype, normal_record)
    assert_equal 1, @genotype.attribute_map['teststatus']

    abnormal_record = build_raw_record('pseudo_id1' => 'bob')
    abnormal_record.raw_fields['testresult'] = 'Heterozygous variant detected'
    @handler.add_test_status(@genotype, abnormal_record)
    assert @handler.abnormal?(@genotype)

    mosaic_record = build_raw_record('pseudo_id1' => 'bob')
    mosaic_record.raw_fields['testresult'] = 'Heterozygous variant detected (mosaic)'
    @handler.add_test_status(@genotype, mosaic_record)
    assert @handler.abnormal?(@genotype)
    assert_equal 6, @genotype.attribute_map['geneticinheritance']

    fail_cannot_interpret_data_record = build_raw_record('pseudo_id1' => 'bob')
    fail_cannot_interpret_data_record.raw_fields['testresult'] = 'Fail - Cannot Interpret Data'
    @handler.add_test_status(@genotype, fail_cannot_interpret_data_record )
    assert_equal 9, @genotype.attribute_map['teststatus']

    fail_record = build_raw_record('pseudo_id1' => 'bob')
    fail_record.raw_fields['testresult'] = 'Fail'
    @handler.add_test_status(@genotype, fail_record)
    assert_equal 9, @genotype.attribute_map['teststatus']
  end

  test 'process_targ' do
    abnormal_targ_record = build_raw_record('pseudo_id1' => 'bob')
    abnormal_targ_record.raw_fields['testscope'] = 'Targeted mutation analysis'
    abnormal_targ_record.raw_fields['testresult'] = 'Heterozygous variant detected'
    abnormal_targ_record.raw_fields['codingdnasequencechange'] = 'c.7988A>T'
    abnormal_targ_record.raw_fields['proteinimpact'] = 'p.Glu143Ter'
    abnormal_targ_record.raw_fields['gene'] = 'BRCA1'
    @handler.add_genetictestscope(@genotype, abnormal_targ_record)
    @handler.add_test_status(@genotype, abnormal_targ_record)
    genotypes = @handler.process_variants_from_record(@genotype, abnormal_targ_record)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.7988A>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Glu143Ter', genotypes[0].attribute_map['proteinimpact']
    assert_equal 7, genotypes[0].attribute_map['gene']
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'REP',
      consultantcode: 'C9999998',
      specimentype: '5',
      servicereportidentifier: 'S100001',
      requesteddate: '2020-06-28T00:00:00.000+01:00',
      authoriseddate: '2020-07-28T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { 'hospitalcode' => 'REP',
      'investigation' => 'BRCA 1&2 (Familial Breast Cancer)',
      'testscope' => 'Targeted mutation analysis',
      'testmethod' => 'Sanger Sequencing',
      'testresult' => 'No variants detected',
      'gene' => 'BRCA2',
      'codingdnasequencechange' => 'n/a',
      'proteinimpact' => 'n/a' }.to_json
  end
end
