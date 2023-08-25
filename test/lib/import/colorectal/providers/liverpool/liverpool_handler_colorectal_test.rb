require 'test_helper'

class LiverpoolHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record('pseudo_id1' => 'bob')
    @genocolorectal = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Liverpool::LiverpoolHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestscope' do
    targ_record = build_raw_record('pseudo_id1' => 'bob')
    @handler.add_genetictestscope(@genocolorectal, targ_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    ashkenazi_record = build_raw_record('pseudo_id1' => 'bob')
    ashkenazi_record.raw_fields['testscope'] = 'Targeted mutation panel'
    @handler.add_genetictestscope(@genocolorectal, ashkenazi_record)
    assert_equal 'AJ Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    fs_record = build_raw_record('pseudo_id1' => 'bob')
    fs_record.raw_fields['testscope'] = 'Partial gene screen'
    @handler.add_genetictestscope(@genocolorectal, fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    partial_gene_mutation_screen_record = build_raw_record('pseudo_id1' => 'bob')
    partial_gene_mutation_screen_record.raw_fields['testscope'] = 'Partial gene mutation screen'
    @handler.add_genetictestscope(@genocolorectal, partial_gene_mutation_screen_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    sanger_mlpa_record = build_raw_record('pseudo_id1' => 'bob')
    sanger_mlpa_record.raw_fields['testscope'] = 'Sanger Sequence analysis and MLPA screen'
    @handler.add_genetictestscope(@genocolorectal, sanger_mlpa_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    mlpa_record = build_raw_record('pseudo_id1' => 'bob')
    mlpa_record.raw_fields['testscope'] = 'targeted mutation analysis - mlpa'
    @handler.add_genetictestscope(@genocolorectal,  mlpa_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    sanger_record = build_raw_record('pseudo_id1' => 'bob')
    sanger_record.raw_fields['testscope'] = 'targeted mutation analysis - sanger sequencing'
    @handler.add_genetictestscope(@genocolorectal, sanger_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    no_scope_record = build_raw_record('pseudo_id1' => 'bob')
    no_scope_record.raw_fields['testscope'] = 'XYZ'
    @genocolorectal = Import::Colorectal::Core::Genocolorectal.new(no_scope_record)
    @handler.add_genetictestscope(@genocolorectal, no_scope_record)
    assert_equal 'Unable to assign Colorectal Lynch or MMR genetictestscope', @genocolorectal.attribute_map['genetictestscope']
  end

  test 'process_teststatus' do
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['testresult'] = 'No variants detected'
    @handler.add_test_status(@genocolorectal, normal_record)
    assert_equal 1, @genocolorectal.attribute_map['teststatus']

    abnormal_record = build_raw_record('pseudo_id1' => 'bob')
    abnormal_record.raw_fields['testresult'] = 'Heterozygous variant detected'
    @handler.add_test_status(@genocolorectal, abnormal_record)
    assert @handler.abnormal?(@genocolorectal)

    mosaic_record = build_raw_record('pseudo_id1' => 'bob')
    mosaic_record.raw_fields['testresult'] = 'Heterozygous variant detected (mosaic)'
    @handler.add_test_status(@genocolorectal, mosaic_record)
    assert @handler.abnormal?(@genocolorectal)
    assert_equal 6, @genocolorectal.attribute_map['geneticinheritance']

    fail_cannot_interpret_data_record = build_raw_record('pseudo_id1' => 'bob')
    fail_cannot_interpret_data_record.raw_fields['testresult'] = 'Fail - Cannot Interpret Data'
    @handler.add_test_status(@genocolorectal, fail_cannot_interpret_data_record)
    assert_equal 9, @genocolorectal.attribute_map['teststatus']

    fail_record = build_raw_record('pseudo_id1' => 'bob')
    fail_record.raw_fields['testresult'] = 'Fail'
    @handler.add_test_status(@genocolorectal, fail_record)
    assert_equal 9, @genocolorectal.attribute_map['teststatus']
  end

  test 'process_targ' do
    abnormal_targ_record = build_raw_record('pseudo_id1' => 'bob')
    abnormal_targ_record.raw_fields['testscope'] = 'Targeted mutation analysis'
    abnormal_targ_record.raw_fields['testresult'] = 'Heterozygous variant detected'
    abnormal_targ_record.raw_fields['codingdnasequencechange'] = 'c.7988A>T'
    abnormal_targ_record.raw_fields['proteinimpact'] = 'p.Glu143Ter'
    abnormal_targ_record.raw_fields['gene'] = 'MSH2'
    @handler.add_genetictestscope(@genocolorectal, abnormal_targ_record)
    @handler.add_test_status(@genocolorectal, abnormal_targ_record)
    genotypes = @handler.process_variants_from_record(@genocolorectal, abnormal_targ_record)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 'c.7988A>T', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Glu143Ter', genotypes[0].attribute_map['proteinimpact']
    assert_equal 2804, genotypes[0].attribute_map['gene']
  end

  test 'process_normal_fs' do
    normal_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normal_fs_record.raw_fields['testscope'] = 'Full gene screen'
    normal_fs_record.raw_fields['testresult'] = 'Heterozygous variant detected'
    normal_fs_record.raw_fields['codingdnasequencechange'] = 'Deletion of exons 2-6'
    normal_fs_record.raw_fields['proteinimpact'] = 'n/a'
    normal_fs_record.raw_fields['gene'] = 'MSH2'
    @handler.add_genetictestscope(@genocolorectal, normal_fs_record)
    @handler.add_test_status(@genocolorectal, normal_fs_record)
    genotypes = @handler.process_variants_from_record(@genocolorectal, normal_fs_record)
    assert_equal 1, genotypes.size
    assert_equal 'Full screen Colorectal Lynch or MMR', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal '2-6', genotypes[0].attribute_map['exonintroncodonnumber']
    assert_equal 2804, genotypes[0].attribute_map['gene']
    assert_equal 3, genotypes[0].attribute_map['sequencevarianttype']
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'REP',
      consultantcode: 'C9999998',
      specimentype: '5',
      servicereportidentifier: 'S100001',
      requesteddate: '2011-05-03T00:00:00.000+01:00',
      authoriseddate: '2011-05-03T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { 'hospitalcode' => 'REP',
      'investigation' => 'HNPCC (MLH1 MSH2 MSH6)',
      'testscope' => 'Targeted mutation analysis',
      'testmethod' => 'Sanger Sequencing',
      'testresult' => 'No variants detected',
      'gene' => 'MLH1',
      'codingdnasequencechange' => 'n/a',
      'proteinimpact' => 'n/a' }.to_json
  end
end
