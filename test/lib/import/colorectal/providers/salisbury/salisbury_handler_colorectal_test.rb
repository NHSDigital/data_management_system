require 'test_helper'
# require 'import/genotype.rb'
# require 'import/colorectal/core/genotype_mmr.rb'
# require 'import/brca/core/provider_handler'
# require 'import/storage_manager/persister'

class SalisburyHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @logger = Import::Log.get_logger
    @logger.level = Logger::INFO
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Salisbury::SalisburyHandlerColorectal.new(EBatch.new)
    end
  end

  test 'process_multigene_normal_record' do
    multigene_normal_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_normal_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    multigene_normal_record.raw_fields['status'] = 'Normal'
    multigene_normal_record.raw_fields['genotype'] = ''
    res = @handler.add_colorectal_from_raw_test(@genotype, multigene_normal_record)
    assert_equal 2, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 2804, res[1].attribute_map['gene']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_multigene_failed_record' do
    multigene_failed_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_failed_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    multigene_failed_record.raw_fields['status'] = 'Fail'
    multigene_failed_record.raw_fields['genotype'] = ''
    res = @handler.add_colorectal_from_raw_test(@genotype, multigene_failed_record)
    assert_equal 2, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
    assert_equal 2804, res[1].attribute_map['gene']
    assert_equal 9, res[1].attribute_map['teststatus']
  end

  test 'process_multigene_multicnv_variant_record' do
    multigene_multicnv_variants_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_multicnv_variants_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    multigene_multicnv_variants_record.raw_fields['status'] = 'Pathogenic'
    multigene_multicnv_variants_record.raw_fields['genotype'] = 'Heterozygous deletion including '\
                                                                'MSH2 exons 1-7 and EPCAM exon 9'
    res = @handler.add_colorectal_from_raw_test(@genotype, multigene_multicnv_variants_record)
    assert_equal 3, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 2804, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal '1-7', res[1].attribute_map['exonintroncodonnumber']
    assert_equal 1432, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
    assert_equal '9', res[2].attribute_map['exonintroncodonnumber']
  end

  test 'process_multigene_singlecnv_record' do
    multigene_onecnv_variant_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_onecnv_variant_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    multigene_onecnv_variant_record.raw_fields['status'] = 'Pathogenic'
    multigene_onecnv_variant_record.raw_fields['genotype'] = 'Deletion of MSH2 exons 9, 10 and 11'
    res = @handler.add_colorectal_from_raw_test(@genotype, multigene_onecnv_variant_record)
    assert_equal 2, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 2804, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal '9', res[1].attribute_map['exonintroncodonnumber']
  end

  test 'process_multigene_positivecnv_noinfo_record' do
    multigene_noinformation_variant_record = build_raw_record('pseudo_id1' => 'bob')
    multigene_noinformation_variant_record.raw_fields['test'] = 'MLH1 and MSH2 test'
    multigene_noinformation_variant_record.raw_fields['status'] = 'Pathogenic'
    multigene_noinformation_variant_record.raw_fields['genotype'] = 'EPCAM and MSH2 exon 1-5'
    res = @handler.add_colorectal_from_raw_test(@genotype, multigene_noinformation_variant_record)
    assert_equal 3, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 1432, res[1].attribute_map['gene']
    assert_equal 2, res[1].attribute_map['teststatus']
    assert_equal 2804, res[2].attribute_map['gene']
    assert_equal 2, res[2].attribute_map['teststatus']
  end

  test 'process_singlegene_normal_record' do
    singlegene_normal_record = build_raw_record('pseudo_id1' => 'bob')
    singlegene_normal_record.raw_fields['test'] = 'hMSH2 exon 14'
    singlegene_normal_record.raw_fields['status'] = 'Normal'
    singlegene_normal_record.raw_fields['genotype'] = ''
    res = @handler.add_colorectal_from_raw_test(@genotype, singlegene_normal_record)
    assert_equal 1, res.size
    assert_equal 2804, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_singlegene_failed_record' do
    singlegene_failed_record = build_raw_record('pseudo_id1' => 'bob')
    singlegene_failed_record.raw_fields['test'] = 'MLH1 mutation analysis'
    singlegene_failed_record.raw_fields['status'] = 'Gaps present'
    singlegene_failed_record.raw_fields['genotype'] = ''
    res = @handler.add_colorectal_from_raw_test(@genotype, singlegene_failed_record)
    assert_equal 1, res.size
    assert_equal 2744, res[0].attribute_map['gene']
    assert_equal 9, res[0].attribute_map['teststatus']
  end

  test 'process_singlegene_falsepositive_record' do
    singlegene_falsepositive_record = build_raw_record('pseudo_id1' => 'bob')
    singlegene_falsepositive_record.raw_fields['test'] = 'MSH6 mutation analysis'
    singlegene_falsepositive_record.raw_fields['status'] = 'Pathogenic'
    singlegene_falsepositive_record.raw_fields['genotype'] = ''
    res = @handler.add_colorectal_from_raw_test(@genotype, singlegene_falsepositive_record)
    assert_equal 1, res.size
    assert_equal 2808, res[0].attribute_map['gene']
    assert_equal 1, res[0].attribute_map['teststatus']
  end

  test 'process_singlegene_exonvariant_record' do
    singlegene_exonvariant_record = build_raw_record('pseudo_id1' => 'bob')
    singlegene_exonvariant_record.raw_fields['test'] = 'PMS2 MLPA'
    singlegene_exonvariant_record.raw_fields['status'] = 'Pathogenic'
    singlegene_exonvariant_record.raw_fields['genotype'] = 'Heterozygous deletion of PMS2 exons 6-8'
    res = @handler.add_colorectal_from_raw_test(@genotype, singlegene_exonvariant_record)
    assert_equal 1, res.size
    assert_equal 3394, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal '6-8', res[0].attribute_map['exonintroncodonnumber']
  end

  test 'process_singlegene_cdnavariant_record' do
    singlegene_exonvariant_record = build_raw_record('pseudo_id1' => 'bob')
    singlegene_exonvariant_record.raw_fields['test'] = 'hMSH6 exon 4F'
    singlegene_exonvariant_record.raw_fields['status'] = 'Pathogenic'
    singlegene_exonvariant_record.raw_fields['genotype'] = 'c.2665C>T p.(Glu889Ter)'
    res = @handler.add_colorectal_from_raw_test(@genotype, singlegene_exonvariant_record)
    assert_equal 1, res.size
    assert_equal 2808, res[0].attribute_map['gene']
    assert_equal 2, res[0].attribute_map['teststatus']
    assert_equal 'c.2665C>T', res[0].attribute_map['codingdnasequencechange']
  end

  private

  def clinical_json
    { sex: '1',
      consultantcode: 'C9999998',
      providercode: 'RJ1',
      receiveddate: '2018-11-22T00:00:00.000+00:00',
      authoriseddate: '2018-11-29T00:00:00.000+00:00',
      servicereportidentifier: 'W1234567',
      sortdate: '2018-11-22T00:00:00.000+00:00',
      specimentype: '12',
      requesteddate: '2018-11-22T00:00:00.000+00:00',
      age: 56 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Male',
      providercode: 'DNA Laboratory (Guys)',
      consultantname: 'Dr Very Good',
      servicereportidentifier: 'W1234567',
      'service level': 'NHS',
      moleculartestingtype: 'HNPCC predictives',
      requesteddate: '2018-11-22 00:00:00',
      receiveddate: '2018-11-22 00:00:00',
      authoriseddate: '2018-11-29 09:43:13',
      specimentype: 'External D N A',
      status: 'Likely pathogenic',
      genotype: 'c.1621A>C p.(Ser541Arg)',
      test: 'hMSH6 exon 4C' }.to_json
  end
end
