require 'test_helper'

class SalisburyHandlerTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)

    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Salisbury::SalisburyHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'extract_gene' do
    gene = @handler.extract_gene(@record.raw_fields['test'], @record.raw_fields['genotype'], @record)
    assert_equal 'BRCA2', gene[0]
  end

  test 'extract_teststatus' do
    @handler.extract_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['status'] = 'Failed'
    @handler.extract_teststatus(@genotype, broken_record)
    assert_equal 9, @genotype.attribute_map['teststatus']
  end

  test 'process_variants' do
    @handler.process_variants(@genotype, @record.raw_fields['genotype'])
    assert_equal 'c.9382C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg3128Ter', @genotype.attribute_map['proteinimpact']
    assert_equal 1, @genotype.attribute_map['sequencevarianttype']
  end

  test 'add_organisationcode_testresult' do
    @handler.add_organisationcode_testresult(@genotype)
    assert_equal '699H0', @genotype.attribute_map['organisationcode_testresult']
  end

  test 'process_ngs_fs_record' do
    ngs_fs_record = build_raw_record('pseudo_id1' => 'bob')
    ngs_fs_record.raw_fields['moleculartestingtype'] = 'Breast and Ovarian cancer 3-gene Panel (R208)'
    ngs_fs_record.raw_fields['status'] = 'No mutation detected'
    ngs_fs_record.raw_fields['test'] = 'NGS results'
    ngs_fs_record.raw_fields['genotype'] = nil
    @handler.process_molecular_testing(@genotype, ngs_fs_record)
    @handler.extract_teststatus(@genotype, ngs_fs_record)
    genotypes = @handler.process_variant_record(@genotype, ngs_fs_record)
    assert_equal 2, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 7, genotypes[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 8, genotypes[1].attribute_map['gene']
  end

  test 'targeted_rec' do
    targ_rec = build_raw_record('pseudo_id1' => 'bob')
    targ_rec.raw_fields['moleculartestingtype'] = 'Breast cancer predictives'
    targ_rec.raw_fields['status'] = 'Normal'
    targ_rec.raw_fields['test'] = 'BC2_11J'
    targ_rec.raw_fields['genotype'] = nil
    @handler.process_molecular_testing(@genotype, targ_rec)
    @handler.extract_teststatus(@genotype, targ_rec)
    genotypes = @handler.process_variant_record(@genotype, targ_rec)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
  end

  test 'targeted_rec_path' do
    targ_rec_path = build_raw_record('pseudo_id1' => 'bob')
    targ_rec_path.raw_fields['moleculartestingtype'] = 'Breast cancer predictives'
    targ_rec_path.raw_fields['status'] = 'Pathogenic'
    targ_rec_path.raw_fields['test'] = 'BC2_02'
    targ_rec_path.raw_fields['genotype'] = 'c.51_52delAC p.(Arg18LeufsTer12)'
    @handler.process_molecular_testing(@genotype, targ_rec_path)
    @handler.extract_teststatus(@genotype, targ_rec_path)
    genotypes = @handler.process_variant_record(@genotype, targ_rec_path)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 'c.51_52del', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg18LeufsTer12', genotypes[0].attribute_map['proteinimpact']
  end

  test 'fs_rec_path' do
    fs_rec_path = build_raw_record('pseudo_id1' => 'bob')
    fs_rec_path.raw_fields['moleculartestingtype'] = 'Breast cancer full screen'
    fs_rec_path.raw_fields['status'] = 'Likely pathogenic'
    fs_rec_path.raw_fields['test'] = 'BRCA2 mutation analysis'
    fs_rec_path.raw_fields['genotype'] = 'c.68-7T>A'
    @handler.process_molecular_testing(@genotype, fs_rec_path)
    @handler.extract_teststatus(@genotype, fs_rec_path)
    genotypes = @handler.process_variant_record(@genotype, fs_rec_path)
    assert_equal 1, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 'c.68-7T>A', genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal 1, genotypes[0].attribute_map['sequencevarianttype']
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      receiveddate: '2017-06-20T00: 00: 00.000+01: 00',
      authoriseddate: '2017-07-25T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      requesteddate: '2017-06-20',
      specimentype: '5',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      providercode: 'Provider Name',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      service_level: 'NHS',
      moleculartestingtype: 'Breast cancer full screen',
      requesteddate: '2017-06-20 00: 00: 00',
      receiveddate: '2017-06-20 00: 00: 00',
      authoriseddate: '2017-07-25 10: 08: 18',
      specimentype: 'Blood',
      status: 'Pathogenic mutation detected',
      genotype: 'c.9382C>T p.(Arg3128Ter)',
      test: 'BRCA2 mutation analysis' }.to_json
  end
end
