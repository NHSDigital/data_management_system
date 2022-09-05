require 'test_helper'

class GuysHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Guys::GuysHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
    @logger.level = Logger::WARN
  end

  test 'normal_ashkenazi_test' do
    res = @handler.process_fields(@record)
    assert_equal 2, res.size
    assert_equal 'AJ BRCA screen', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'brca1_mutated_ashkenazi_test' do
    mutated_record = build_raw_record('pseudo_id1' => 'bob')
    mutated_record.raw_fields['brca1 mutation'] = 'c.123A>G'
    mutated_record.raw_fields['ashkenazi assay result'] = '123A>G'
    res = @handler.process_fields(mutated_record)
    assert_equal 2, res.size
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'c.123A>G', res[0].attribute_map['codingdnasequencechange']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'brca2_mutated_ashkenazi_test' do
    mutated_record = build_raw_record('pseudo_id1' => 'bob')
    mutated_record.raw_fields['brca2 mutation'] = 'c.5946delT (M)'
    mutated_record.raw_fields['ashkenazi assay result'] = '5946delT'
    res = @handler.process_fields(mutated_record)
    assert_equal 2, res.size
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'c.5946del', res[0].attribute_map['codingdnasequencechange']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
  end

  test 'brca1_mutated_ashkenazi_exception_test' do
    mutated_record = build_raw_record('pseudo_id1' => 'bob')
    mutated_record.raw_fields['ashkenazi assay result'] = 'het c.68_69delAG (p.Glu23fs)'
    res = @handler.process_fields(mutated_record)
    assert_equal 2, res.size
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'c.68_69del', res[0].attribute_map['codingdnasequencechange']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'brca2_mutated_ashkenazi_exception_test' do
    mutated_record = build_raw_record('pseudo_id1' => 'bob')
    mutated_record.raw_fields['ashkenazi assay result'] = 'c.5946delT (M)'
    res = @handler.process_fields(mutated_record)
    assert_equal 2, res.size
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'c.5946del', res[0].attribute_map['codingdnasequencechange']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
  end

  test 'normal_polish_test' do
    polish_record = build_raw_record('pseudo_id1' => 'bob')
    polish_record.raw_fields['ashkenazi assay result'] = nil
    polish_record.raw_fields['ashkenazi assay report date'] = nil
    polish_record.raw_fields['polish assay result'] = 'NEG'
    polish_record.raw_fields['polish assay report date'] = '2016-10-25 00:00:00'
    res = @handler.process_fields(polish_record)
    assert_equal 1, res.size
    assert_equal 'Polish BRCA screen', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
  end

  test 'mutated_polish_test' do
    polish_mutated_record = build_raw_record('pseudo_id1' => 'bob')
    polish_mutated_record.raw_fields['ashkenazi assay result'] = nil
    polish_mutated_record.raw_fields['ashkenazi assay report date'] = nil
    polish_mutated_record.raw_fields['brca1 mutation'] = 'c.5266dupC p.(Gln1756fs) (M)'
    polish_mutated_record.raw_fields['polish assay result'] = 'c.5266dupC p.(Gln1756fs) (M)'
    polish_mutated_record.raw_fields['polish assay report date'] = '2016-10-25 00:00:00'
    res = @handler.process_fields(polish_mutated_record)
    assert_equal 1, res.size
    assert_equal 'Polish BRCA screen', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'c.5266dupC', res[0].attribute_map['codingdnasequencechange']
  end

  test 'all_fields_nil_targeted1_test' do
    allnilfields_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    allnilfields_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    allnilfields_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    allnilfields_targeted1_record.raw_fields['polish assay result'] = nil
    res = @handler.process_fields(allnilfields_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
  end

  test 'malformed_mutated_targeted1_test' do
    malformed_mutated_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    malformed_mutated_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    malformed_mutated_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    malformed_mutated_targeted1_record.raw_fields['polish assay result'] = nil
    malformed_mutated_targeted1_record.raw_fields['brca1 mutation'] = 'IVS6-1G>A (M)'
    res = @handler.process_fields(malformed_mutated_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'c.ivs6-1G>A', res[0].attribute_map['codingdnasequencechange']
  end

  test 'normal_targeted1_test' do
    normal_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    normal_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    normal_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    normal_targeted1_record.raw_fields['polish assay result'] = nil
    normal_targeted1_record.raw_fields['brca1 seq result'] = '-VE'
    res = @handler.process_fields(normal_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
  end

  test 'brca2_cdna_variant_targeted1_test' do
    brca2_cdna_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_cdna_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca2_cdna_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    brca2_cdna_targeted1_record.raw_fields['polish assay result'] = nil
    brca2_cdna_targeted1_record.raw_fields['brca2 mutation'] = 'N/c.7988A>T (p.Glu2663Val) (M)'
    brca2_cdna_targeted1_record.raw_fields['brca2 seq result'] = 'N/c.7988A>T (p.Glu2663Val) (M)'
    res = @handler.process_fields(brca2_cdna_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'c.7988A>T', res[0].attribute_map['codingdnasequencechange']
  end

  test 'brca1_exon_variant_targeted1_test' do
    brca1_exon_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_exon_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca1_exon_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    brca1_exon_targeted1_record.raw_fields['polish assay result'] = nil
    brca1_exon_targeted1_record.raw_fields['brca1 mutation'] = 'exon 3 Het Del (M)'
    brca1_exon_targeted1_record.raw_fields['brca1 seq result'] = 'BRCA1 exon 3 Het Del (M)'
    res = @handler.process_fields(brca1_exon_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
  end

  test 'brca1_normal_exon_targeted1_test' do
    brca1_normal_exon_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_normal_exon_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca1_normal_exon_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    brca1_normal_exon_targeted1_record.raw_fields['polish assay result'] = nil
    brca1_normal_exon_targeted1_record.raw_fields['brca1 mlpa results'] = 'No Del/Dup'
    brca1_normal_exon_targeted1_record.raw_fields['brca2 mlpa results'] = 'N/A'
    res = @handler.process_fields(brca1_normal_exon_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
  end

  test 'brca2_failed_exon_targeted1_test' do
    brca1_normal_exon_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_normal_exon_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca1_normal_exon_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    brca1_normal_exon_targeted1_record.raw_fields['polish assay result'] = nil
    brca1_normal_exon_targeted1_record.raw_fields['brca2 mlpa results'] = 'FAIL; NO DEL EX21-24'
    res = @handler.process_fields(brca1_normal_exon_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
  end

  test 'no_cdna_no_exon_targeted1_test' do
    no_cdna_no_exon_targeted1_record = build_raw_record('pseudo_id1' => 'bob')
    no_cdna_no_exon_targeted1_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    no_cdna_no_exon_targeted1_record.raw_fields['ashkenazi assay result'] = nil
    no_cdna_no_exon_targeted1_record.raw_fields['polish assay result'] = nil
    no_cdna_no_exon_targeted1_record.raw_fields['brca1 mlpa results'] = 'N/A'
    no_cdna_no_exon_targeted1_record.raw_fields['brca2 mlpa results'] = 'N/A'
    res = @handler.process_fields(no_cdna_no_exon_targeted1_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
  end

  test 'brca1_cdna_variant_targeted2_test' do
    brca1_cdna_targeted2_record = build_raw_record('pseudo_id1' => 'bob')
    # brca1_cdna_targeted2_record.raw_fields['predictive'] = 'true'
    brca1_cdna_targeted2_record.raw_fields['polish assay result'] = nil
    brca1_cdna_targeted2_record.raw_fields['ashkenazi assay result'] = 'NEG'
    brca1_cdna_targeted2_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca1_cdna_targeted2_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_cdna_targeted2_record.raw_fields['brca1 mutation'] = 'c.357_358delAGinsT (M)'
    res = @handler.process_fields(brca1_cdna_targeted2_record)
    assert_equal 3, res.size
    assert_equal 'Targeted BRCA mutation test', res[2].attribute_map['genetictestscope']
    assert_equal 7, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
  end

  test 'brca_all_nil_targeted4_test' do
    brca_all_nil_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca_all_nil_targeted4_record.raw_fields['predictive'] = 'true'
    brca_all_nil_targeted4_record.raw_fields['polish assay result'] = nil
    brca_all_nil_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca_all_nil_targeted4_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca_all_nil_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca_all_nil_targeted4_record.raw_fields['brca1 mutation'] = nil
    brca_all_nil_targeted4_record.raw_fields['brca1 mlpa results'] = nil
    brca_all_nil_targeted4_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca_all_nil_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
  end

  test 'brca2_normal_targeted4_test' do
    brca2_normal_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_normal_targeted4_record.raw_fields['predictive'] = 'true'
    brca2_normal_targeted4_record.raw_fields['polish assay result'] = nil
    brca2_normal_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca2_normal_targeted4_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca2_normal_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_normal_targeted4_record.raw_fields['brca1 mutation'] = nil
    brca2_normal_targeted4_record.raw_fields['brca1 mlpa results'] = nil
    brca2_normal_targeted4_record.raw_fields['brca2 mlpa results'] = nil
    brca2_normal_targeted4_record.raw_fields['brca2 seq result'] = '-VE'
    res = @handler.process_fields(brca2_normal_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'brca1_cdna_variant_targeted4_test' do
    brca1_cdna_variant_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_cdna_variant_targeted4_record.raw_fields['predictive'] = 'true'
    brca1_cdna_variant_targeted4_record.raw_fields['polish assay result'] = nil
    brca1_cdna_variant_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca1_cdna_variant_targeted4_record.raw_fields['predictive report date'] = '2010-05-27 00:00:00'
    brca1_cdna_variant_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_cdna_variant_targeted4_record.raw_fields['brca1 mutation'] = '2080delA (M)'
    brca1_cdna_variant_targeted4_record.raw_fields['brca1 mlpa results'] = nil
    brca1_cdna_variant_targeted4_record.raw_fields['brca2 mlpa results'] = nil
    brca1_cdna_variant_targeted4_record.raw_fields['brca1 seq result'] = '2080delA (M)'
    res = @handler.process_fields(brca1_cdna_variant_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.2080del', res[0].attribute_map['codingdnasequencechange']
  end

  test 'brca1_mlpa_variant_targeted4_test' do
    brca1_mlpa_variant_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_mlpa_variant_targeted4_record.raw_fields['predictive'] = 'true'
    brca1_mlpa_variant_targeted4_record.raw_fields['polish assay result'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['predictive report date'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['brca1 mutation'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['brca1 mlpa results'] = 'Het del ex19'
    brca1_mlpa_variant_targeted4_record.raw_fields['brca2 mlpa results'] = nil
    brca1_mlpa_variant_targeted4_record.raw_fields['brca1 seq result'] = nil
    res = @handler.process_fields(brca1_mlpa_variant_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
  end

  test 'brca1_mlpa_normal_targeted4_test' do
    brca1_mlpa_normal_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_mlpa_normal_targeted4_record.raw_fields['predictive'] = 'true'
    brca1_mlpa_normal_targeted4_record.raw_fields['polish assay result'] = nil
    brca1_mlpa_normal_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca1_mlpa_normal_targeted4_record.raw_fields['predictive report date'] = nil
    brca1_mlpa_normal_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_mlpa_normal_targeted4_record.raw_fields['brca1 mutation'] = nil
    brca1_mlpa_normal_targeted4_record.raw_fields['brca1 mlpa results'] = 'No del/dup'
    brca1_mlpa_normal_targeted4_record.raw_fields['brca1 seq result'] = nil
    res = @handler.process_fields(brca1_mlpa_normal_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'brca1_malformed_cdna_targeted4_test' do
    brca1_malformed_cdna_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_malformed_cdna_targeted4_record.raw_fields['predictive'] = 'true'
    brca1_malformed_cdna_targeted4_record.raw_fields['polish assay result'] = nil
    brca1_malformed_cdna_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca1_malformed_cdna_targeted4_record.raw_fields['predictive report date'] = nil
    brca1_malformed_cdna_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_malformed_cdna_targeted4_record.raw_fields['brca1 mutation'] = 'IVS8+1G>T (M)'
    brca1_malformed_cdna_targeted4_record.raw_fields['brca1 mlpa results'] = nil
    brca1_malformed_cdna_targeted4_record.raw_fields['brca1 seq result'] = 'IVS8+1G>T (M)'
    res = @handler.process_fields(brca1_malformed_cdna_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.ivs8+1G>T', res[0].attribute_map['codingdnasequencechange']
  end

  test 'brca2_malformed_cdna_targeted4_test' do
    brca2_malformed_cdna_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_malformed_cdna_targeted4_record.raw_fields['predictive'] = 'true'
    brca2_malformed_cdna_targeted4_record.raw_fields['polish assay result'] = nil
    brca2_malformed_cdna_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca2_malformed_cdna_targeted4_record.raw_fields['predictive report date'] = nil
    brca2_malformed_cdna_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_malformed_cdna_targeted4_record.raw_fields['brca2 mutation'] = '+VE for Y3098X'
    brca2_malformed_cdna_targeted4_record.raw_fields['brca1 mlpa results'] = nil
    brca2_malformed_cdna_targeted4_record.raw_fields['brca2 seq result'] = '+VE for Y3098X'
    res = @handler.process_fields(brca2_malformed_cdna_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.+ve', res[0].attribute_map['codingdnasequencechange']
  end

  test 'brca2_no_cdna_no_mlpa_targeted4_test' do
    brca2_no_cdna_no_mlpa_targeted4_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['predictive'] = 'true'
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['polish assay result'] = nil
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['ashkenazi assay result'] = nil
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['predictive report date'] = nil
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['brca1 mlpa results'] = 'N/A'
    brca2_no_cdna_no_mlpa_targeted4_record.raw_fields['brca2 mlpa results'] = 'N/A'
    res = @handler.process_fields(brca2_no_cdna_no_mlpa_targeted4_record)
    assert_equal 1, res.size
    assert_equal 'Targeted BRCA mutation test', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
  end

  test 'normal_brca_fullscreen1_test' do
    normal_brca_fullscreen1_record = build_raw_record('pseudo_id1' => 'bob')
    normal_brca_fullscreen1_record.raw_fields['predictive'] = 'false'
    normal_brca_fullscreen1_record.raw_fields['polish assay result'] = nil
    normal_brca_fullscreen1_record.raw_fields['ashkenazi assay result'] = nil
    normal_brca_fullscreen1_record.raw_fields['predictive report date'] = nil
    normal_brca_fullscreen1_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    normal_brca_fullscreen1_record.raw_fields['ngs result'] = 'No mutation'
    normal_brca_fullscreen1_record.raw_fields['ashkenazi assay report date'] = nil
    normal_brca_fullscreen1_record.raw_fields['brca1 mlpa results'] = nil
    normal_brca_fullscreen1_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(normal_brca_fullscreen1_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'failed_brca_fullscreen1_test' do
    failed_brca_fullscreen1_record = build_raw_record('pseudo_id1' => 'bob')
    failed_brca_fullscreen1_record.raw_fields['predictive'] = 'false'
    failed_brca_fullscreen1_record.raw_fields['polish assay result'] = nil
    failed_brca_fullscreen1_record.raw_fields['ashkenazi assay result'] = nil
    failed_brca_fullscreen1_record.raw_fields['predictive report date'] = nil
    failed_brca_fullscreen1_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    failed_brca_fullscreen1_record.raw_fields['ngs result'] = 'failed due to coverage'
    failed_brca_fullscreen1_record.raw_fields['ashkenazi assay report date'] = nil
    failed_brca_fullscreen1_record.raw_fields['brca1 mlpa results'] = nil
    failed_brca_fullscreen1_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(failed_brca_fullscreen1_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 9, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'deprecated_genename_cdna_variant_brca_fullscreen1_test' do
    deprecated_genename_cdna_variant_brca_fullscreen1_record = build_raw_record('pseudo_id1' => 'bob')
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['predictive'] = 'false'
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['polish assay result'] = nil
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['ashkenazi assay result'] = nil
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['predictive report date'] = nil
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['ngs result'] = 'B2 Het c.3599_3600delGT p.(Cys1200Ter)(C5) (M)'
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['ashkenazi assay report date'] = nil
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['brca1 mlpa results'] = nil
    deprecated_genename_cdna_variant_brca_fullscreen1_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(deprecated_genename_cdna_variant_brca_fullscreen1_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'c.3599_3600del', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca_double_cdna_variant_fullscreen1_test' do
    brca_double_cdna_variant_fullscreen1_record = build_raw_record('pseudo_id1' => 'bob')
    brca_double_cdna_variant_fullscreen1_record.raw_fields['predictive'] = 'false'
    brca_double_cdna_variant_fullscreen1_record.raw_fields['polish assay result'] = nil
    brca_double_cdna_variant_fullscreen1_record.raw_fields['ashkenazi assay result'] = nil
    brca_double_cdna_variant_fullscreen1_record.raw_fields['predictive report date'] = nil
    brca_double_cdna_variant_fullscreen1_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca_double_cdna_variant_fullscreen1_record.raw_fields['ngs result'] = 'BRCA2 c.7480C>T p.(Arg2494Ter) (M) Class5; BRCA1 BRCA1 Het c.5332+4A>G (C3 UV)'
    brca_double_cdna_variant_fullscreen1_record.raw_fields['ashkenazi assay report date'] = nil
    brca_double_cdna_variant_fullscreen1_record.raw_fields['brca1 mlpa results'] = nil
    brca_double_cdna_variant_fullscreen1_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca_double_cdna_variant_fullscreen1_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'c.7480C>T', res[0].attribute_map['codingdnasequencechange']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'c.5332+4A>G', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca2_cdna_variant_brca1_normal_fullscreen1_test' do
    brca2_cdna_variant_brca1_normal_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_cdna_variant_brca1_normal_record.raw_fields['predictive'] = 'false'
    brca2_cdna_variant_brca1_normal_record.raw_fields['polish assay result'] = nil
    brca2_cdna_variant_brca1_normal_record.raw_fields['ashkenazi assay result'] = nil
    brca2_cdna_variant_brca1_normal_record.raw_fields['predictive report date'] = nil
    brca2_cdna_variant_brca1_normal_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca2_cdna_variant_brca1_normal_record.raw_fields['ngs result'] = 'BRCA2 het c.347_350delGTCT p.(Ser116fs) (M) Class 5'
    brca2_cdna_variant_brca1_normal_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_cdna_variant_brca1_normal_record.raw_fields['brca1 mlpa results'] = nil
    brca2_cdna_variant_brca1_normal_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca2_cdna_variant_brca1_normal_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'c.347_350del', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca1_cdna_variant_brca2_normal_fullscreen1_test' do
    brca1_cdna_variant_brca2_normal_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_cdna_variant_brca2_normal_record.raw_fields['predictive'] = 'false'
    brca1_cdna_variant_brca2_normal_record.raw_fields['polish assay result'] = nil
    brca1_cdna_variant_brca2_normal_record.raw_fields['ashkenazi assay result'] = nil
    brca1_cdna_variant_brca2_normal_record.raw_fields['predictive report date'] = nil
    brca1_cdna_variant_brca2_normal_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca1_cdna_variant_brca2_normal_record.raw_fields['ngs result'] = 'BRCA1 Het c.5266dupC p.(Gln1756fs)(M)(C5)'
    brca1_cdna_variant_brca2_normal_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_cdna_variant_brca2_normal_record.raw_fields['brca1 mlpa results'] = nil
    brca1_cdna_variant_brca2_normal_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca1_cdna_variant_brca2_normal_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'c.5266dupC', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca2_exon_variant_brca1_normal_fullscreen1_test' do
    brca2_exon_variant_brca1_normal_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_exon_variant_brca1_normal_record.raw_fields['predictive'] = 'false'
    brca2_exon_variant_brca1_normal_record.raw_fields['polish assay result'] = nil
    brca2_exon_variant_brca1_normal_record.raw_fields['ashkenazi assay result'] = nil
    brca2_exon_variant_brca1_normal_record.raw_fields['predictive report date'] = nil
    brca2_exon_variant_brca1_normal_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca2_exon_variant_brca1_normal_record.raw_fields['ngs result'] = 'BRCA2 Ex14-16 het del'
    brca2_exon_variant_brca1_normal_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_exon_variant_brca1_normal_record.raw_fields['brca1 mlpa results'] = nil
    brca2_exon_variant_brca1_normal_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca2_exon_variant_brca1_normal_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
  end

  test 'brca1_exon_variant_brca2_normal_fullscreen1_test' do
    brca1_exon_variant_brca2_normal_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_exon_variant_brca2_normal_record.raw_fields['predictive'] = 'false'
    brca1_exon_variant_brca2_normal_record.raw_fields['polish assay result'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['ashkenazi assay result'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['predictive report date'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca1_exon_variant_brca2_normal_record.raw_fields['ngs result'] = 'BRCA1 Het del ex1-2 (M) C5'
    brca1_exon_variant_brca2_normal_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['brca1 mlpa results'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca1_exon_variant_brca2_normal_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
  end

  test 'nonbrca_cdnavariant_fullscreen1_test' do
    brca1_exon_variant_brca2_normal_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_exon_variant_brca2_normal_record.raw_fields['predictive'] = 'false'
    brca1_exon_variant_brca2_normal_record.raw_fields['polish assay result'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['ashkenazi assay result'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['predictive report date'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca1_exon_variant_brca2_normal_record.raw_fields['ngs result'] = 'CHEK2: Het c.1100delC  p.(Thr367fs)'
    brca1_exon_variant_brca2_normal_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['brca1 mlpa results'] = nil
    brca1_exon_variant_brca2_normal_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca1_exon_variant_brca2_normal_record)
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 865, res[2].attribute_map['gene']
    assert_equal 'c.1100del', res[2].attribute_map['codingdnasequencechange']
  end

  test 'brca2_malformed_cdnavariant_fullscreen1_test' do
    brca2_malformed_cdnavariant_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_malformed_cdnavariant_record.raw_fields['predictive'] = 'false'
    brca2_malformed_cdnavariant_record.raw_fields['polish assay result'] = nil
    brca2_malformed_cdnavariant_record.raw_fields['ashkenazi assay result'] = nil
    brca2_malformed_cdnavariant_record.raw_fields['predictive report date'] = nil
    brca2_malformed_cdnavariant_record.raw_fields['ngs report date'] = '2014-11-11 00:00:00'
    brca2_malformed_cdnavariant_record.raw_fields['ngs result'] = 'BRCA2 7558C>T p.(Arg2520Ter) (C5) (M)'
    brca2_malformed_cdnavariant_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_malformed_cdnavariant_record.raw_fields['brca1 mlpa results'] = nil
    brca2_malformed_cdnavariant_record.raw_fields['brca2 mlpa results'] = nil
    res = @handler.process_fields(brca2_malformed_cdnavariant_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.7558C>T', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca_double_fail_fullscreen2_test' do
    brca_double_normal_fullscreen2_record = build_raw_record('pseudo_id1' => 'bob')
    brca_double_normal_fullscreen2_record.raw_fields['predictive'] = 'false'
    brca_double_normal_fullscreen2_record.raw_fields['polish assay result'] = nil
    brca_double_normal_fullscreen2_record.raw_fields['ashkenazi assay result'] = nil
    brca_double_normal_fullscreen2_record.raw_fields['predictive report date'] = nil
    brca_double_normal_fullscreen2_record.raw_fields['ashkenazi assay report date'] = nil
    brca_double_normal_fullscreen2_record.raw_fields['brca1 mlpa results'] = 'FAIL; no del/dup'
    brca_double_normal_fullscreen2_record.raw_fields['brca2 mlpa results'] = 'FAIL; no del/dup'
    res = @handler.process_fields(brca_double_normal_fullscreen2_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca2_cdna_varint_fullscreen2_test' do
    brca2_cdna_varint_fullscreen2_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_cdna_varint_fullscreen2_record.raw_fields['predictive'] = 'false'
    brca2_cdna_varint_fullscreen2_record.raw_fields['polish assay result'] = nil
    brca2_cdna_varint_fullscreen2_record.raw_fields['ashkenazi assay result'] = nil
    brca2_cdna_varint_fullscreen2_record.raw_fields['predictive report date'] = nil
    brca2_cdna_varint_fullscreen2_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_cdna_varint_fullscreen2_record.raw_fields['brca1 mutation'] = nil
    brca2_cdna_varint_fullscreen2_record.raw_fields['brca2 mutation'] = 'N/c.7758G>A (p.Trp2586X) (M)'
    brca2_cdna_varint_fullscreen2_record.raw_fields['full screen result'] = 'BRCA1 No testing Ex 0 BRCA2 N/c.7758G>A (p.Trp2586X) (M) Ex 2-9, 12-27'
    res = @handler.process_fields(brca2_cdna_varint_fullscreen2_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'c.7758G>A', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca1_cdna_varint_fullscreen2_test' do
    brca1_cdna_varint_fullscreen2_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_cdna_varint_fullscreen2_record.raw_fields['predictive'] = 'false'
    brca1_cdna_varint_fullscreen2_record.raw_fields['polish assay result'] = nil
    brca1_cdna_varint_fullscreen2_record.raw_fields['ashkenazi assay result'] = nil
    brca1_cdna_varint_fullscreen2_record.raw_fields['predictive report date'] = nil
    brca1_cdna_varint_fullscreen2_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_cdna_varint_fullscreen2_record.raw_fields['brca1 mutation'] = 'c.5110T>C p.Phe1704Leu (M)'
    brca1_cdna_varint_fullscreen2_record.raw_fields['brca2 mutation'] = nil
    brca1_cdna_varint_fullscreen2_record.raw_fields['full screen result'] = 'BRCA1 c.5110T>C p.Phe1704Leu (M)'
    res = @handler.process_fields(brca1_cdna_varint_fullscreen2_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'c.5110T>C', res[1].attribute_map['codingdnasequencechange']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca2_cdna_varint_fsresult_only_fullscreen2_test' do
    brca2_cdna_varint_fsresult_only_fullscreen2_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['predictive'] = 'false'
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['polish assay result'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['ashkenazi assay result'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['predictive report date'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['brca1 mutation'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['brca2 mutation'] = nil
    brca2_cdna_varint_fsresult_only_fullscreen2_record.raw_fields['full screen result'] = 'BRCA2 c.1-11C>T (UV)'
    res = @handler.process_fields(brca2_cdna_varint_fsresult_only_fullscreen2_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 'c.1-11C>T', res[0].attribute_map['codingdnasequencechange']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca1_exon_variant_fullscreen2_test' do
    brca1_exon_variant_fullscreen2 = build_raw_record('pseudo_id1' => 'bob')
    brca1_exon_variant_fullscreen2.raw_fields['predictive'] = 'false'
    brca1_exon_variant_fullscreen2.raw_fields['polish assay result'] = nil
    brca1_exon_variant_fullscreen2.raw_fields['ashkenazi assay result'] = nil
    brca1_exon_variant_fullscreen2.raw_fields['predictive report date'] = nil
    brca1_exon_variant_fullscreen2.raw_fields['ashkenazi assay report date'] = nil
    brca1_exon_variant_fullscreen2.raw_fields['brca1 mlpa results'] = 'Ex8-9 Het Del'
    brca1_exon_variant_fullscreen2.raw_fields['brca2 mlpa results'] = 'No del/dup'
    brca1_exon_variant_fullscreen2.raw_fields['full screen result'] = 'BRCA1 Het c.305C>G (p.Ala102Gly) (UV); BRCA2 Het c.7806-40A>G (UV); Het c.8460A>C (p.Val2820Val) (UV)'
    res = @handler.process_fields(brca1_exon_variant_fullscreen2)
    assert_equal 3, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal 8, res[2].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'all_fields_nil_fullscreen2_test' do
    all_fields_nil_fullscreen2 = build_raw_record('pseudo_id1' => 'bob')
    all_fields_nil_fullscreen2.raw_fields['predictive'] = 'false'
    all_fields_nil_fullscreen2.raw_fields['polish assay result'] = nil
    all_fields_nil_fullscreen2.raw_fields['ashkenazi assay result'] = nil
    all_fields_nil_fullscreen2.raw_fields['predictive report date'] = nil
    all_fields_nil_fullscreen2.raw_fields['ashkenazi assay report date'] = nil
    all_fields_nil_fullscreen2.raw_fields['brca1 mlpa results'] = nil
    all_fields_nil_fullscreen2.raw_fields['brca2 mlpa results'] = nil
    all_fields_nil_fullscreen2.raw_fields['full screen result'] = nil
    all_fields_nil_fullscreen2.raw_fields['authoriseddate'] = '2015-04-21 00:00:00'
    res = @handler.process_fields(all_fields_nil_fullscreen2)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca1_nil_brca2_normal_fullscreen2_test' do
    all_fields_nil_fullscreen2 = build_raw_record('pseudo_id1' => 'bob')
    all_fields_nil_fullscreen2.raw_fields['predictive'] = 'false'
    all_fields_nil_fullscreen2.raw_fields['polish assay result'] = nil
    all_fields_nil_fullscreen2.raw_fields['ashkenazi assay result'] = nil
    all_fields_nil_fullscreen2.raw_fields['predictive report date'] = nil
    all_fields_nil_fullscreen2.raw_fields['ashkenazi assay report date'] = nil
    all_fields_nil_fullscreen2.raw_fields['brca1 mlpa results'] = nil
    all_fields_nil_fullscreen2.raw_fields['brca2 mlpa results'] = 'No del/dup'
    all_fields_nil_fullscreen2.raw_fields['full screen result'] = nil
    all_fields_nil_fullscreen2.raw_fields['authoriseddate'] = '2015-04-21 00:00:00'
    res = @handler.process_fields(all_fields_nil_fullscreen2)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'all_fields_nil_fullscreen3_test' do
    all_fields_nil_fullscreen3 = build_raw_record('pseudo_id1' => 'bob')
    all_fields_nil_fullscreen3.raw_fields['predictive'] = 'false'
    all_fields_nil_fullscreen3.raw_fields['polish assay result'] = nil
    all_fields_nil_fullscreen3.raw_fields['ashkenazi assay result'] = nil
    all_fields_nil_fullscreen3.raw_fields['predictive report date'] = nil
    all_fields_nil_fullscreen3.raw_fields['ashkenazi assay report date'] = nil
    all_fields_nil_fullscreen3.raw_fields['brca1 mlpa results'] = nil
    all_fields_nil_fullscreen3.raw_fields['brca2 mlpa results'] = nil
    all_fields_nil_fullscreen3.raw_fields['full screen result'] = nil
    all_fields_nil_fullscreen3.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(all_fields_nil_fullscreen3)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 4, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 4, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca2_normal_brca1_nil_fullscreen3_test' do
    brca2_normal_brca1_nil_fullscreen3 = build_raw_record('pseudo_id1' => 'bob')
    brca2_normal_brca1_nil_fullscreen3.raw_fields['predictive'] = 'false'
    brca2_normal_brca1_nil_fullscreen3.raw_fields['polish assay result'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['ashkenazi assay result'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['predictive report date'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['ashkenazi assay report date'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['brca1 mlpa results'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['brca2 mlpa results'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['brca2 seq result'] = 'Neg for R2034C'
    brca2_normal_brca1_nil_fullscreen3.raw_fields['full screen result'] = nil
    brca2_normal_brca1_nil_fullscreen3.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca2_normal_brca1_nil_fullscreen3)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca1_malformedcdna_brca2_nil_fullscreen3_test' do
    brca1_malformedcdna_brca2_normal = build_raw_record('pseudo_id1' => 'bob')
    brca1_malformedcdna_brca2_normal.raw_fields['predictive'] = 'false'
    brca1_malformedcdna_brca2_normal.raw_fields['polish assay result'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['ashkenazi assay result'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['predictive report date'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['ashkenazi assay report date'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['brca1 mutation'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['brca2 mlpa results'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['brca1 seq result'] = '5544G>T (V1809F)'
    brca1_malformedcdna_brca2_normal.raw_fields['brca2 seq result'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['full screen result'] = nil
    brca1_malformedcdna_brca2_normal.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca1_malformedcdna_brca2_normal)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.5544G>T', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca2_malformedcdna_brca1_nil_fullscreen3_test' do
    brca2_malformedcdna_brca1_normal = build_raw_record('pseudo_id1' => 'bob')
    brca2_malformedcdna_brca1_normal.raw_fields['predictive'] = 'false'
    brca2_malformedcdna_brca1_normal.raw_fields['polish assay result'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['ashkenazi assay result'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['predictive report date'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['ashkenazi assay report date'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['brca1 mutation'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['brca2 mlpa results'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['brca1 seq result'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['brca2 seq result'] = 'N1910del (UV)'
    brca2_malformedcdna_brca1_normal.raw_fields['full screen result'] = nil
    brca2_malformedcdna_brca1_normal.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca2_malformedcdna_brca1_normal)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.n1910del', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca1_cdna_variant_fullscreen3_test' do
    brca1_cdna_variant_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_cdna_variant_record.raw_fields['predictive'] = 'false'
    brca1_cdna_variant_record.raw_fields['polish assay result'] = nil
    brca1_cdna_variant_record.raw_fields['ashkenazi assay result'] = nil
    brca1_cdna_variant_record.raw_fields['predictive report date'] = nil
    brca1_cdna_variant_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_cdna_variant_record.raw_fields['brca1 mutation'] = '5382insC (M)'
    brca1_cdna_variant_record.raw_fields['brca2 mlpa results'] = nil
    brca1_cdna_variant_record.raw_fields['brca1 seq result'] = nil
    brca1_cdna_variant_record.raw_fields['brca2 seq result'] = nil
    brca1_cdna_variant_record.raw_fields['full screen result'] = nil
    brca1_cdna_variant_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca1_cdna_variant_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.5382insC', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca2_cdna_variant_fullscreen3_test' do
    brca2_cdna_variant_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_cdna_variant_record.raw_fields['predictive'] = 'false'
    brca2_cdna_variant_record.raw_fields['polish assay result'] = nil
    brca2_cdna_variant_record.raw_fields['ashkenazi assay result'] = nil
    brca2_cdna_variant_record.raw_fields['predictive report date'] = nil
    brca2_cdna_variant_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_cdna_variant_record.raw_fields['brca2 mutation'] = '6174delT (M)'
    brca2_cdna_variant_record.raw_fields['brca2 mlpa results'] = nil
    brca2_cdna_variant_record.raw_fields['brca1 seq result'] = nil
    brca2_cdna_variant_record.raw_fields['brca2 seq result'] = '6174delT (M)'
    brca2_cdna_variant_record.raw_fields['full screen result'] = nil
    brca2_cdna_variant_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca2_cdna_variant_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.6174del', res[1].attribute_map['codingdnasequencechange']
  end

  test 'brca_mlpa_double_normal_fullscreen3_test' do
    brca_mlpa_double_normal_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['predictive'] = 'false'
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['polish assay result'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['predictive report date'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['brca1 mutation'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['brca2 mlpa results'] = 'No del/dup'
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['brca1 mlpa results'] = 'No del/dup'
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['brca1 seq result'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['brca2 seq result'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['full screen result'] = nil
    brca_mlpa_double_normal_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca_mlpa_double_normal_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca_1_exon_variant_fullscreen3_test' do
    brca1_exon_variant_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_exon_variant_fullscreen3_record.raw_fields['predictive'] = 'false'
    brca1_exon_variant_fullscreen3_record.raw_fields['polish assay result'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['predictive report date'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['brca1 mutation'] = 'Het Del Ex21-22 (M)'
    brca1_exon_variant_fullscreen3_record.raw_fields['brca2 mlpa results'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['brca1 mlpa results'] = 'Het Del Ex21-22 (M)'
    brca1_exon_variant_fullscreen3_record.raw_fields['brca1 seq result'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['brca2 seq result'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['full screen result'] = nil
    brca1_exon_variant_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca1_exon_variant_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 8, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 7, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca2_exon_variant_fullscreen3_test' do
    brca2_exon_variant_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    brca2_exon_variant_fullscreen3_record.raw_fields['predictive'] = 'false'
    brca2_exon_variant_fullscreen3_record.raw_fields['polish assay result'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['predictive report date'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['brca2 mutation'] = 'HET DEL EX 21-24 (M)'
    brca2_exon_variant_fullscreen3_record.raw_fields['brca2 mlpa results'] = 'HET DEL EX 21-24'
    brca2_exon_variant_fullscreen3_record.raw_fields['brca1 mlpa results'] = 'No del/dup'
    brca2_exon_variant_fullscreen3_record.raw_fields['brca1 seq result'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['brca2 seq result'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['full screen result'] = nil
    brca2_exon_variant_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca2_exon_variant_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'double_brca_mlformed_variant_fullscreen3_test' do
    double_brca_mlformed_variant_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['predictive'] = 'false'
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['polish assay result'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['predictive report date'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['brca2 mutation'] = 'HET DEL EX 21-24 (M)'
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['brca2 mlpa results'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['brca1 mlpa results'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['brca1 seq result'] = '4158A>G'
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['brca2 seq result'] = '7691G>A (UV)'
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['full screen result'] = nil
    double_brca_mlformed_variant_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(double_brca_mlformed_variant_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 'c.4158A>G', res[0].attribute_map['codingdnasequencechange']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
    assert_equal 'c.7691G>A', res[1].attribute_map['codingdnasequencechange']
  end

  test 'double_brca_mlpa_fail_fullscreen3_test' do
    double_brca_mlpa_fail_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['predictive'] = 'false'
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['polish assay result'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['predictive report date'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['brca2 mutation'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['brca2 mlpa results'] = 'Fail/degraded'
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['brca1 mlpa results'] = 'Fail/degraded'
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['brca1 seq result'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['brca2 seq result'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['full screen result'] = nil
    double_brca_mlpa_fail_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(double_brca_mlpa_fail_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  test 'brca1_nil_brca2_normal_mlpa_fullscreen3_test' do
    brca1_nil_brca2_normal_mlpa_fullscreen3_record = build_raw_record('pseudo_id1' => 'bob')
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['predictive'] = 'false'
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['polish assay result'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['ashkenazi assay result'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['predictive report date'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['ashkenazi assay report date'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['brca2 mutation'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['brca1 mlpa results'] = 'N/A'
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['brca2 mlpa results'] = 'No del/dup'
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['brca1 seq result'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['brca2 seq result'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['full screen result'] = nil
    brca1_nil_brca2_normal_mlpa_fullscreen3_record.raw_fields['authoriseddate'] = nil
    res = @handler.process_fields(brca1_nil_brca2_normal_mlpa_fullscreen3_record)
    assert_equal 2, res.size
    assert_equal 'Full screen BRCA1 and BRCA2', res[0].attribute_map['genetictestscope']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 7, res[0].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
    assert_equal 8, res[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', res[1].attribute_map['genetictestscope']
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      receiveddate: '2009-04-28T00:00:00.000+01:00',
      servicereportidentifier: 'ServiceReportIdentifier',
      age: '999' }.to_json
  end

  def rawtext_clinical_json
    { 'consultantname' => 'Watts',
      'providercode' => "Guy's Hospital",
      'referring centre' => nil,
      'servicereportidentifier' => 'SRI',
      'spec no 2' => nil,
      'spec no 3' => nil,
      'requesteddate' => nil,
      'receiveddate' => nil,
      'data location' => nil,
      'predictive test performed overall' => nil,
      'predictive report date' => nil,
      'predictive date given' => nil,
      'predictive' => 'cabbage',
      'brca1 mutation' => nil,
      'brca2 mutation' => nil,
      'u variant' => nil,
      'brca1 mlpa results' => nil,
      'brca2 mlpa results' => nil,
      'brca1 seq result' => nil,
      'brca2 seq result' => nil,
      'date 2/3 reported' => nil,
      'full brca1 report date' => nil,
      'full brca2 report date' => nil,
      'brca2 ptt report date' => nil,
      'full ptt report date' => nil,
      'authoriseddate' => nil,
      'full screen resul' => nil,
      'ngs report date' => nil,
      'ngs result' => nil,
      'polish assay report date' => nil,
      'polish assay result' => nil,
      'ashkenazi assay report date' => '2010-08-10 00:00:00',
      'ashkenazi assay result' => 'NEG',
      moleculartestingtype: 'Predictive' }.to_json
  end
end
