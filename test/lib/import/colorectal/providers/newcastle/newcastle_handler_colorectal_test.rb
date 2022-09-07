require 'test_helper'

class NewcastleHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Newcastle::NewcastleHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'add_test_status' do
    positive_record = build_raw_record('pseudo_id1' => 'bob')
    @handler.add_test_status(@genotype, positive_record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    fail_record = build_raw_record('pseudo_id1' => 'bob')
    fail_record.raw_fields['variantpathclass'] = 'benign'
    fail_record.raw_fields['teststatus'] = 'fail'
    @handler.add_test_status(@genotype, fail_record)
    assert_equal 9, @genotype.attribute_map['teststatus']
    unknown_record = build_raw_record('pseudo_id1' => 'bob')
    unknown_record.raw_fields['gene'] = 'APC'
    unknown_record.raw_fields['genotype'] = ''
    unknown_record.raw_fields['variantpathclass'] = 'nmd'
    @handler.add_test_status(@genotype, unknown_record)
    assert_equal 4, @genotype.attribute_map['teststatus']
  end

  test 'add_test_scope' do
    @handler.add_test_scope(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['service category'] = 'Cabbage'
    targeted_record.raw_fields['moleculartestingtype'] = 'carrier'
    @handler.add_test_scope(@genotype, targeted_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'process_variant_records' do
    @handler.add_test_scope(@genotype, @record)
    @handler.add_test_status(@genotype, @record)
    genocolorectals = @handler.process_variant_records(@genotype, @record)
    assert_equal 5, genocolorectals.size
    assert_equal 'c.1569dupT', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg524fs', @genotype.attribute_map['proteinimpact']
  end

  test 'process_targ_exon_variant' do
    targ_exon_record = build_raw_record('pseudo_id1' => 'bob')
    targ_exon_record.raw_fields['service category'] = 'B'
    targ_exon_record.raw_fields['moleculartestingtype'] = 'Presymptomatic test'
    targ_exon_record.raw_fields['investigation code'] = 'HNPCC'
    targ_exon_record.raw_fields['gene'] = 'MSH2'
    targ_exon_record.raw_fields['genotype'] = 'exon del 11-16'
    targ_exon_record.raw_fields['variantpathclass'] = 'pathogenic'
    targ_exon_record.raw_fields['teststatus'] = 'het'
    @handler.add_test_scope(@genotype, targ_exon_record)
    @handler.add_test_status(@genotype, targ_exon_record)
    genocolorectals = @handler.process_variant_records(@genotype, targ_exon_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    assert_equal 1, genocolorectals.size
    assert_equal 2804, genocolorectals[0].attribute_map['gene']
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
    assert_nil genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_nil genocolorectals[0].attribute_map['proteinimpact']
    assert_equal '11-16', genocolorectals[0].attribute_map['exonintroncodonnumber']
  end

  test 'process_malformed_cdna_fs' do
    fs_mal_cdna_rec = build_raw_record('pseudo_id1' => 'bob')
    fs_mal_cdna_rec.raw_fields['service category'] = 'O'
    fs_mal_cdna_rec.raw_fields['moleculartestingtype'] = 'Diagnostic test'
    fs_mal_cdna_rec.raw_fields['investigation code'] = 'HNPCC'
    fs_mal_cdna_rec.raw_fields['gene'] = 'MSH6'
    fs_mal_cdna_rec.raw_fields['genotype'] = 'c3716_3717delTA'
    fs_mal_cdna_rec.raw_fields['variantpathclass'] = 'pathogenic'
    fs_mal_cdna_rec.raw_fields['teststatus'] = 'het'
    @handler.add_test_scope(@genotype, fs_mal_cdna_rec)
    @handler.add_test_status(@genotype, fs_mal_cdna_rec)
    genocolorectals = @handler.process_variant_records(@genotype, fs_mal_cdna_rec)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    assert_equal 5, genocolorectals.size
    assert_equal 2808, genocolorectals[4].attribute_map['gene']
    assert_equal 2, genocolorectals[4].attribute_map['teststatus']
    assert_equal 'c.3716_3717del', genocolorectals[4].attribute_map['codingdnasequencechange']
    assert_nil genocolorectals[4].attribute_map['proteinimpact']
    assert_equal 2744, genocolorectals[0].attribute_map['gene']
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_nil genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 2804, genocolorectals[1].attribute_map['gene']
    assert_equal 1, genocolorectals[1].attribute_map['teststatus']
    assert_nil genocolorectals[1].attribute_map['codingdnasequencechange']
    assert_equal 3394, genocolorectals[2].attribute_map['gene']
    assert_equal 1, genocolorectals[2].attribute_map['teststatus']
    assert_nil genocolorectals[2].attribute_map['codingdnasequencechange']
    assert_equal 1432, genocolorectals[3].attribute_map['gene']
    assert_equal 1, genocolorectals[3].attribute_map['teststatus']
  end

  test 'process_fail_record' do
    fail_rec = build_raw_record('pseudo_id1' => 'bob')
    fail_rec.raw_fields['service category'] = 'B'
    fail_rec.raw_fields['moleculartestingtype'] = 'Carrier test'
    fail_rec.raw_fields['investigation code'] = 'HNPCC'
    fail_rec.raw_fields['gene'] = ''
    fail_rec.raw_fields['genotype'] = ''
    fail_rec.raw_fields['variantpathclass'] = ''
    fail_rec.raw_fields['teststatus'] = 'fail'
    @handler.add_test_scope(@genotype, fail_rec)
    @handler.add_test_status(@genotype, fail_rec)
    genocolorectals = @handler.process_variant_records(@genotype, fail_rec)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    assert_equal 1, genocolorectals.size
    assert_equal 9, genocolorectals[0].attribute_map['teststatus']
    assert_nil genocolorectals[0].attribute_map['gene']
  end

  test 'process_unknown_rec' do
    unknown_rec = build_raw_record('pseudo_id1' => 'bob')
    unknown_rec.raw_fields['service category'] = 'A2'
    unknown_rec.raw_fields['moleculartestingtype'] = 'Diag - symptoms'
    unknown_rec.raw_fields['investigation code'] = 'HNPCC_pred'
    unknown_rec.raw_fields['gene'] = 'MSH6'
    unknown_rec.raw_fields['genotype'] = ''
    unknown_rec.raw_fields['variantpathclass'] = ''
    unknown_rec.raw_fields['teststatus'] = 'het'
    @handler.add_test_scope(@genotype, unknown_rec)
    @handler.add_test_status(@genotype, unknown_rec)
    genocolorectals = @handler.process_variant_records(@genotype, unknown_rec)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    assert_equal 1, genocolorectals.size
    assert_equal 4, genocolorectals[0].attribute_map['teststatus']
    assert_equal 2808, genocolorectals[0].attribute_map['gene']
  end

  test 'process_negative_record' do
    neg_rec = build_raw_record('pseudo_id1' => 'bob')
    neg_rec.raw_fields['service category'] = 'O'
    neg_rec.raw_fields['moleculartestingtype'] = 'Diagnosis'
    neg_rec.raw_fields['investigation code'] = 'HNPCC'
    neg_rec.raw_fields['gene'] = ''
    neg_rec.raw_fields['genotype'] = ''
    neg_rec.raw_fields['variantpathclass'] = ''
    neg_rec.raw_fields['teststatus'] = 'nmd'
    @handler.add_test_scope(@genotype, neg_rec)
    @handler.add_test_status(@genotype, neg_rec)
    genocolorectals = @handler.process_variant_records(@genotype, neg_rec)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    assert_equal 5, genocolorectals.size
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_equal 2744, genocolorectals[0].attribute_map['gene']
    assert_equal 1, genocolorectals[1].attribute_map['teststatus']
    assert_equal 2804, genocolorectals[1].attribute_map['gene']
  end

  test 'do_not_process_brca_records' do
    brca_record = build_raw_record('pseudo_id1' => 'bob')
    brca_record.raw_fields['service category'] = 'A2'
    brca_record.raw_fields['moleculartestingtype'] = 'Diagnostic'
    brca_record.raw_fields['investigation code'] = 'BRCA-PRED'
    brca_record.raw_fields['gene'] = 'BRCA2'
    brca_record.raw_fields['genotype'] = 'c.3847_3848delGT (p.Val1283Lysfs*2)*'
    brca_record.raw_fields['variantpathclass'] = ''
    brca_record.raw_fields['teststatus'] = 'het'

    assert_no_difference -> { Pseudo::GeneticTestResult.count } do
      @handler.process_fields(brca_record)
    end
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2008-03-11T00:00:00.000+00:00',
      authoriseddate: '2009-11-02T00:00:00.000+00:00',
      sortdate: '2008-03-11T00:00:00.000+00:00',
      specimentype: '5',
      gene: '2804',
      variantpathclass: 'pathogenic',
      requesteddate: '2009-08-14T00:00:00.000+01:00',
      age: 99999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      providercode: 'Provider Address',
      consultantname: 'Clinician Name',
      servicereportidentifier: 'Service Report Identifier',
      'service category' => 'O',
      moleculartestingtype: 'Diagnostic test',
      'investigation code' => 'HNPCC',
      gene: 'MSH2',
      genotype: 'c.1569dupT (p.Arg524fs)',
      variantpathclass: 'pathogenic',
      teststatus: 'het',
      specimentype: 'Blood',
      receiveddate: '2008-03-11 00:00:00',
      requesteddate: '2009-08-14 00:00:00',
      authoriseddate: '2009-11-02 00:00:00' }.to_json
  end
end
