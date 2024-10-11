require 'test_helper'

class SalisburyHandlerTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)

    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Salisbury::SalisburyHandler.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'extract_teststatus_row_level' do
    @handler.assign_status_var(@record.raw_fields.first)
    assert_equal 2, @handler.extract_teststatus_row_level
    broken_record = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    broken_record.raw_fields.first['status'] = 'Failed'
    @handler.assign_status_var(broken_record.raw_fields.first)
    assert_equal 9, @handler.extract_teststatus_row_level
  end

  test 'process_variants' do
    @handler.process_variants(@genotype, @record.raw_fields.first['genotype'])
    assert_equal 'c.9382C>T', @genotype.attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg3128Ter', @genotype.attribute_map['proteinimpact']
    assert_equal 1, @genotype.attribute_map['sequencevarianttype']
  end

  test 'process_exonic_variants' do
    exonic_record = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    exonic_record.raw_fields.first['genotype'] = 'exons 21-24'
    @handler.process_variants(@genotype, exonic_record.raw_fields.first['genotype'])
    assert_equal '21-24', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 10, @genotype.attribute_map['sequencevarianttype']
    assert_equal 1, @genotype.attribute_map['variantlocation']
  end

  test 'add_organisationcode_testresult' do
    @handler.add_organisationcode_testresult(@genotype)
    assert_equal '699H0', @genotype.attribute_map['organisationcode_testresult']
  end

  test 'targeted_rec' do
    targ_rec = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    targ_rec.raw_fields.first['moleculartestingtype'] = 'Breast cancer predictives'
    targ_rec.raw_fields.first['status'] = 'Normal'
    targ_rec.raw_fields.first['test'] = 'BC2_11J'
    targ_rec.raw_fields.first['genotype'] = nil
    @handler.assign_molecular_testing_var(targ_rec)
    @handler.process_molecular_testing(@genotype)
    @handler.assign_status_var(targ_rec.raw_fields.first)
    @handler.extract_teststatus_row_level
    genotypes = @handler.process_record(@genotype, targ_rec)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
  end

  test 'targeted_rec_path' do
    targ_rec_path = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    targ_rec_path.raw_fields.first['moleculartestingtype'] = 'Breast cancer predictives'
    targ_rec_path.raw_fields.first['status'] = 'Pathogenic'
    targ_rec_path.raw_fields.first['test'] = 'BC2_02'
    targ_rec_path.raw_fields.first['genotype'] = 'c.51_52delAC p.(Arg18LeufsTer12)'
    @handler.assign_molecular_testing_var(targ_rec_path)
    @handler.process_molecular_testing(@genotype)
    @handler.assign_status_var(targ_rec_path.raw_fields.first)
    @handler.extract_teststatus_row_level
    genotypes = @handler.process_record(@genotype, targ_rec_path)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 'c.51_52del', genotypes[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Arg18LeufsTer12', genotypes[0].attribute_map['proteinimpact']
  end

  test 'fs_rec_path' do
    fs_rec_path = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    fs_rec_path.raw_fields.first['moleculartestingtype'] = 'Breast cancer full screen'
    fs_rec_path.raw_fields.first['status'] = 'Likely pathogenic'
    fs_rec_path.raw_fields.first['test'] = 'BRCA2 mutation analysis'
    fs_rec_path.raw_fields.first['genotype'] = 'c.68-7T>A'
    @handler.assign_molecular_testing_var(fs_rec_path)
    @handler.process_molecular_testing(@genotype)
    @handler.assign_status_var(fs_rec_path.raw_fields.first)
    @handler.extract_teststatus_row_level
    genotypes = @handler.process_record(@genotype, fs_rec_path)
    assert_equal 1, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 2, genotypes[0].attribute_map['teststatus']
    assert_equal 8, genotypes[0].attribute_map['gene']
    assert_equal 'c.68-7T>A', genotypes[0].attribute_map['codingdnasequencechange']
    assert_nil genotypes[0].attribute_map['proteinimpact']
    assert_equal 1, genotypes[0].attribute_map['sequencevarianttype']
  end

  test 'no_scope_rec' do
    no_scope_rec = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    no_scope_rec.raw_fields.first['moleculartestingtype'] = 'BRCA MLPA only'
    no_scope_rec.raw_fields.first['status'] = 'No mutation detected'
    @handler.assign_molecular_testing_var(no_scope_rec)
    @handler.process_molecular_testing(@genotype)
    assert_equal 'Unable to assign BRCA genetictestscope', @genotype.attribute_map['genetictestscope']
  end

  test 'add_provider_code' do
    prov_record = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    # For which codes are there
    prov_record.raw_fields.first['providercode'] = 'Royal Cornwall Hospital Trust'
    prov_record.mapped_fields['providercode'] = 'Royal Cornwall Hospital Trust'
    @genotype.add_passthrough_fields(prov_record.mapped_fields, prov_record.raw_fields,
                                     Import::Helpers::Brca::Providers::Rnz::RnzConstants::PASS_THROUGH_FIELDS)
    @handler.add_provider_code(@genotype, prov_record, Import::Helpers::Brca::Providers::Rnz::RnzConstants::ORG_CODE_MAP)
    assert_equal 'REF12', @genotype.attribute_map['providercode']

    # For which codes are not there
    genotype = Import::Brca::Core::GenotypeBrca.new(prov_record)
    prov_record.raw_fields.first['providercode'] = 'North Devon District Hospital'
    prov_record.mapped_fields['providercode'] = 'North Devon District Hospital'
    genotype.add_passthrough_fields(prov_record.mapped_fields, prov_record.raw_fields,
                                    Import::Helpers::Brca::Providers::Rnz::RnzConstants::PASS_THROUGH_FIELDS)
    @handler.add_provider_code(genotype, prov_record, Import::Helpers::Brca::Providers::Rnz::RnzConstants::ORG_CODE_MAP)
    assert_equal 'North Devon District Hospital', genotype.attribute_map['providercode']
  end

  test 'process_ngs_fs__hybrid_record' do
    ngs_fs_record = build_raw_record(raw_hash: second_rawtext_clinical_hash, options: { 'pseudo_id1' => 'bob' })
    ngs_fs_record.raw_fields.first['moleculartestingtype'] = 'Breast and Ovarian cancer 3-gene Panel (R208)'
    ngs_fs_record.raw_fields.first['status'] = 'No mutation detected'
    ngs_fs_record.raw_fields.first['test'] = 'NGS results'
    ngs_fs_record.raw_fields.first['genotype'] = nil
    @handler.assign_molecular_testing_var(ngs_fs_record)
    @handler.process_molecular_testing(@genotype)
    @handler.assign_status_var(ngs_fs_record.raw_fields.first)
    @handler.extract_teststatus_row_level
    genotypes = @handler.process_record(@genotype, ngs_fs_record)
    assert_equal 3, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_nil genotypes[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
    # PALB2 is added separately
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[2].attribute_map['genetictestscope']
    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_equal 3186, genotypes[2].attribute_map['gene']
  end

  test 'process_row_level_record' do
    row_level_record = build_raw_record(options: { 'pseudo_id1' => 'bob' })
    row_level_record.raw_fields.first['moleculartestingtype'] = 'PALB2 targetted testing'
    row_level_record.raw_fields.first['status'] = 'No mutation detected'
    row_level_record.raw_fields.first['test'] = 'PALB2'
    row_level_record.raw_fields.first['genotype'] = nil
    @handler.assign_molecular_testing_var(row_level_record)
    @handler.process_molecular_testing(@genotype)
    @handler.assign_status_var(row_level_record.raw_fields.first)
    @handler.extract_teststatus_row_level
    genotypes = @handler.process_record(@genotype, row_level_record)
    assert_equal 1, genotypes.size
    assert_equal 'Targeted BRCA mutation test', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 3186, genotypes[0].attribute_map['gene']
  end

  test 'process_panel_record' do
    panel_rec = build_raw_record(raw_hash: second_rawtext_clinical_hash, options: { 'pseudo_id1' => 'bob' })
    panel_rec.raw_fields.first['moleculartestingtype'] = 'Breast and ovarian cancer 7-gene panel (R208)'
    panel_rec.raw_fields.first['status'] = 'Normal'
    panel_rec.raw_fields.first['test'] = 'BRCA2 dosage analysis'
    panel_rec.raw_fields.first['genotype'] = nil
    panel_rec.raw_fields[1]['moleculartestingtype'] = 'Breast and ovarian cancer 7-gene panel (R208)'
    @handler.assign_molecular_testing_var(panel_rec)
    @handler.process_molecular_testing(@genotype)
    genotypes = @handler.process_record(@genotype, panel_rec)
    assert_equal 7, genotypes.size
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[0].attribute_map['genetictestscope']
    assert_equal 1, genotypes[0].attribute_map['teststatus']
    assert_equal 451, genotypes[0].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[1].attribute_map['genetictestscope']
    assert_equal 1, genotypes[1].attribute_map['teststatus']
    assert_equal 7, genotypes[1].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[2].attribute_map['genetictestscope']
    assert_equal 1, genotypes[2].attribute_map['teststatus']
    assert_equal 8, genotypes[2].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[3].attribute_map['genetictestscope']
    assert_equal 1, genotypes[3].attribute_map['teststatus']
    assert_equal 865, genotypes[3].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[5].attribute_map['genetictestscope']
    assert_equal 1, genotypes[5].attribute_map['teststatus']
    assert_equal 3615, genotypes[5].attribute_map['gene']
    assert_equal 'Full screen BRCA1 and BRCA2', genotypes[6].attribute_map['genetictestscope']
    assert_equal 1, genotypes[6].attribute_map['teststatus']
    assert_equal 3616, genotypes[6].attribute_map['gene']
  end

  private

  def build_raw_record(raw_hash: {}, options: {})
    default_options = { 'pseudo_id1' => '',
                        'pseudo_id2' => '',
                        'encrypted_demog' => '',
                        'clinical.to_json' => clinical_json,
                        'encrypted_rawtext_demog' => '',
                        'rawtext_clinical.to_json' => rawtext_clinical_json(raw_hash) }
    Import::Germline::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2017-06-20T00: 00: 00.000+01: 00',
      authoriseddate: '2017-07-25T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      requesteddate: '2017-06-20',
      specimentype: '5',
      age: 999 }.to_json
  end

  def first_rawtext_clinical_hash
    { sex: 'Female',
      providercode: 'Provider Name',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      service_level: 'NHS',
      moleculartestingtype: 'Breast and Ovarian cancer 3-gene Panel (R208)',
      requesteddate: '2017-06-20 00: 00: 00',
      receiveddate: '2017-06-20 00: 00: 00',
      authoriseddate: '2017-07-25 10: 08: 18',
      specimentype: 'Blood',
      status: 'Pathogenic mutation detected',
      genotype: 'c.9382C>T p.(Arg3128Ter)',
      test: 'BRCA2 mutation analysis' }
  end

  def second_rawtext_clinical_hash
    { sex: 'Female',
      servicereportidentifier: 'Service Report Identifier',
      moleculartestingtype: 'Breast and Ovarian cancer 3-gene Panel (R208)',
      specimentype: 'External DNA',
      status: 'Normal',
      genotype: nil,
      test: 'BRCA1 dosage analysis' }
  end

  def rawtext_clinical_json(raw_hash)
    raw_json = []
    raw_json << first_rawtext_clinical_hash
    raw_json << raw_hash if raw_hash.present?
    raw_json.to_json
  end
end
