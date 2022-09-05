require 'test_helper'

class LiverpoolHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @extractor = Import::Brca::Providers::Leeds::ReportExtractor::GenotypeAndReportExtractor.new
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
    @handler.add_genetictestscope(@genotype, ashkenazi_record)
    assert_equal 'AJ BRCA screen', @genotype.attribute_map['genetictestscope']

    fs_record = build_raw_record('pseudo_id1' => 'bob')
    fs_record.raw_fields['testscope'] = 'Partial gene screen'
    @handler.add_genetictestscope(@genotype, fs_record)
    assert_equal 'Full screen BRCA1 and BRCA2', @genotype.attribute_map['genetictestscope']
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

    fail_record = build_raw_record('pseudo_id1' => 'bob')
    fail_record.raw_fields['testresult'] = 'Fail - Cannot Interpret Data'
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
