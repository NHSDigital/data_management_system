require 'test_helper'

class SheffieldHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Sheffield::SheffieldHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end


  test 'add_test_scope_from_karyo_fullscreen' do
    @handler.add_test_scope_from_geno_karyo(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'add_test_scope_from_karyo_targeted' do
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    @handler.add_test_scope_from_geno_karyo(@genotype, targeted_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'add_colorectal_from_raw_test_full_screen' do
    @handler.add_test_scope_from_geno_karyo(@genotype, @record)
    raw_test = @handler.process_variants_from_record(@genotype, @record)
    assert_equal 3, raw_test.size
    assert_equal 2744, raw_test[0].attribute_map['gene']
    assert_equal 2, raw_test[0].attribute_map['teststatus']
    assert_equal 2804, raw_test[1].attribute_map['gene']
    assert_equal 1, raw_test[1].attribute_map['teststatus']
    assert_equal 2808, raw_test[2].attribute_map['gene']
    assert_equal 1, raw_test[2].attribute_map['teststatus']
  end

  test 'add_colorectal_from_normal_test_full_screen' do
    normal_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normal_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    normal_fs_record.raw_fields['karyotypingmethod'] = 'Full panel'
    normal_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected'
    @handler.add_test_scope_from_geno_karyo(@genotype, normal_fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    genocolorectals = @handler.process_variants_from_record(@genotype, normal_fs_record)
    assert_equal 13, genocolorectals.size
    assert_equal 2744, genocolorectals[0].attribute_map['gene']
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_equal 2804, genocolorectals[1].attribute_map['gene']
    assert_equal 1, genocolorectals[1].attribute_map['teststatus']
    assert_equal 2808, genocolorectals[2].attribute_map['gene']
    assert_equal 1, genocolorectals[2].attribute_map['teststatus']
    assert_equal 3394, genocolorectals[3].attribute_map['gene']
    assert_equal 1, genocolorectals[3].attribute_map['teststatus']
    assert_equal 1432, genocolorectals[4].attribute_map['gene']
    assert_equal 1, genocolorectals[4].attribute_map['teststatus']
    assert_equal 358, genocolorectals[5].attribute_map['gene']
    assert_equal 1, genocolorectals[5].attribute_map['teststatus']
    assert_equal 2850, genocolorectals[6].attribute_map['gene']
    assert_equal 1, genocolorectals[6].attribute_map['teststatus']
    assert_equal 577, genocolorectals[7].attribute_map['gene']
    assert_equal 1, genocolorectals[7].attribute_map['teststatus']
    assert_equal 62, genocolorectals[8].attribute_map['gene']
    assert_equal 1, genocolorectals[8].attribute_map['teststatus']
    assert_equal 3408, genocolorectals[9].attribute_map['gene']
    assert_equal 1, genocolorectals[9].attribute_map['teststatus']
    assert_equal 5000, genocolorectals[10].attribute_map['gene']
    assert_equal 1, genocolorectals[10].attribute_map['teststatus']
    assert_equal 72, genocolorectals[11].attribute_map['gene']
    assert_equal 1, genocolorectals[11].attribute_map['teststatus']
    assert_equal 76, genocolorectals[12].attribute_map['gene']
    assert_equal 1, genocolorectals[12].attribute_map['teststatus']
  end

  test 'add_colorectal_from_incomplete_test_full_screen' do
    incomplete_fs_record = build_raw_record('pseudo_id1' => 'bob')
    incomplete_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    incomplete_fs_record.raw_fields['karyotypingmethod'] = 'MLH1 MSH2 & MSH6'
    incomplete_fs_record.raw_fields['genotype'] = 'Incomplete analysis - see below'
    @handler.add_test_scope_from_geno_karyo(@genotype, incomplete_fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    genocolorectals = @handler.process_variants_from_record(@genotype, incomplete_fs_record)
    assert_equal 2744, genocolorectals[0].attribute_map['gene']
    assert_equal 2804, genocolorectals[1].attribute_map['gene']
    assert_equal 2808, genocolorectals[2].attribute_map['gene']
    assert_equal 4, genocolorectals[0].attribute_map['teststatus']
    assert_equal 4, genocolorectals[1].attribute_map['teststatus']
    assert_equal 4, genocolorectals[2].attribute_map['teststatus']
  end

  test 'add_colorectal_from_multiple_genes_full_screen' do
    multiplegenes_fs_record = build_raw_record('pseudo_id1' => 'bob')
    multiplegenes_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    multiplegenes_fs_record.raw_fields['karyotypingmethod'] = 'Full panel'
    multiplegenes_fs_record.raw_fields['genotype'] = '"SMAD4:c.[1573A>G];[=]  p.[(Ile525Val)];[(=)] MUTYH: c.[1014G>C ];[=]  p.[(Glu338His)];[(=)] -See below'
    @handler.add_test_scope_from_geno_karyo(@genotype, multiplegenes_fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    genocolorectals = @handler.process_variants_from_record(@genotype, multiplegenes_fs_record)
    assert_equal 13, genocolorectals.size
    assert_equal 'c.1573A>G', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 'c.1014G>C', genocolorectals[1].attribute_map['codingdnasequencechange']
    assert_equal 'p.Ile525Val', genocolorectals[0].attribute_map['proteinimpact']
    assert_equal 'p.Glu338His', genocolorectals[1].attribute_map['proteinimpact']
    assert_equal 72, genocolorectals[0].attribute_map['gene']
    assert_equal 2850, genocolorectals[1].attribute_map['gene']
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
    assert_equal 2, genocolorectals[1].attribute_map['teststatus']
    assert_nil genocolorectals[10].attribute_map['codingdnasequencechange']
    assert_nil genocolorectals[12].attribute_map['codingdnasequencechange']
    assert_nil genocolorectals[10].attribute_map['proteinimpact']
    assert_nil genocolorectals[12].attribute_map['proteinimpact']
    assert_equal 3408, genocolorectals[10].attribute_map['gene']
    assert_equal 76, genocolorectals[12].attribute_map['gene']
    assert_equal 1, genocolorectals[10].attribute_map['teststatus']
    assert_equal 1, genocolorectals[12].attribute_map['teststatus']
  end

  test 'add_colorectal_from_multiple_genes_karyofield_full_screen' do
    normalmultiplekaryo_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normalmultiplekaryo_fs_record.raw_fields['genetictestscope'] = 'R209 :: Inherited colorectal cancer (with or without polyposis)'
    normalmultiplekaryo_fs_record.raw_fields['karyotypingmethod'] = 'R209.1 :: NGS - APC and MUTYH only'
    normalmultiplekaryo_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected'
    @handler.add_test_scope_from_geno_karyo(@genotype, normalmultiplekaryo_fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
    genocolorectals = @handler.process_variants_from_record(@genotype, normalmultiplekaryo_fs_record)
    assert_equal 2, genocolorectals.size
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_equal 1, genocolorectals[1].attribute_map['teststatus']
    assert_equal 358, genocolorectals[0].attribute_map['gene']
    assert_equal 2850, genocolorectals[1].attribute_map['gene']
  end

  test 'add_colorectal_from_raw_test_targeted' do
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    targeted_record.raw_fields['genotype'] = 'c.[2079dup];[2079=]  p.[(Cys694fs)];[(Cys694=)] MSH6 '
    @handler.add_test_scope_from_geno_karyo(@genotype, targeted_record)
    genocolorectals = @handler.process_variants_from_record(@genotype, targeted_record)
    assert_equal 1, genocolorectals.size
    assert_equal 2, genocolorectals[0].attribute_map['teststatus']
    assert_equal 'c.2079dup', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 'p.Cys694fs', genocolorectals[0].attribute_map['proteinimpact']
    assert_equal 2808, genocolorectals[0].attribute_map['gene']
  end

  test 'add_colorectal_from_null_test_targeted' do
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    targeted_record.raw_fields['genotype'] = 'Familial likely pathogenic mutation NOT detected'
    @handler.add_test_scope_from_geno_karyo(@genotype, targeted_record)
    genocolorectals = @handler.process_variants_from_record(@genotype, targeted_record)
    assert_equal 1, genocolorectals[0].attribute_map['teststatus']
    assert_nil genocolorectals[0].attribute_map['gene']
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1653dup')
    @handler.process_cdna_change(@genotype, @record.raw_fields['genotype'])
    assert_equal 'c.1653dup', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'only_protein_impact' do
    only_protein_record = build_raw_record('pseudo_id1' => 'bob')
    only_protein_record.raw_fields['genetictestscope'] = 'FAP'
    only_protein_record.raw_fields['karyotypingmethod'] = 'APC gene sequencing'
    only_protein_record.raw_fields['genotype'] = 'p.([Arg302*];[=])'
    only_protein_record.raw_fields['moleculartestingtype'] = 'Diagnostic testing'
    @handler.add_test_scope_from_geno_karyo(@genotype, only_protein_record)
    genocolorectals = @handler.process_variants_from_record(@genotype, only_protein_record)
    assert_equal 1, genocolorectals.size
    assert_equal 'Full screen Colorectal Lynch or MMR', genocolorectals[0].attribute_map['genetictestscope']
    assert_equal 'p.Arg302', genocolorectals[0].attribute_map['proteinimpact']
    assert_equal 'c.', genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal 358, genocolorectals[0].attribute_map['gene']
  end

  test 'exon deletion record' do
    exon_record = build_raw_record('pseudo_id1' => 'bob')
    exon_record.raw_fields['genetictestscope'] = 'R209 :: Inherited colorectal cancer (with or without polyposis)'
    exon_record.raw_fields['karyotypingmethod'] = 'R209.1 :: Small panel in Leeds'
    exon_record.raw_fields['genotype'] = 'PMS2-PMS2 ex9-10 deletion-Heterozygous-UV5'
    exon_record.raw_fields['moleculartestingtype'] = 'Diagnostic testing'
    @handler.add_test_scope_from_geno_karyo(@genotype, exon_record)
    genocolorectals = @handler.process_variants_from_record(@genotype, exon_record)
    assert_equal 13, genocolorectals.size
    assert_equal 'Full screen Colorectal Lynch or MMR', genocolorectals[0].attribute_map['genetictestscope']
    assert_nil genocolorectals[0].attribute_map['proteinimpact']
    assert_nil genocolorectals[0].attribute_map['codingdnasequencechange']
    assert_equal '9-10', genocolorectals[0].attribute_map['exonintroncodonnumber']
    assert_equal 3, genocolorectals[0].attribute_map['sequencevarianttype']
    assert_equal 3394, genocolorectals[0].attribute_map['gene']
    assert_equal 1, genocolorectals[0].attribute_map['variantgenotype']
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'C1234567',
      providercode: 'Provider Code',
      collecteddate: '2014-01-09T00:00:00.000+00:00',
      receiveddate: '2014-01-09T00:00:00.000+00:00',
      authoriseddate: '2014-04-09T00:00:00.000+01:00',
      servicereportidentifier: 'S1234567',
      sortdate: '2014-01-09T00:00:00.000+00:00',
      genetictestscope: 'Colorectal cancer panel',
      specimentype: '5',
      genotype: 'MLH1: c.[1653dup];[=] p.[(Thr552fs)];[(=)]',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex:                     'Female',
      servicereportidentifier: 'S1234567',
      providercode:            'Provider Code',
      consultantname:          'Consultant Name',
      patienttype:             'NHS',
      moleculartestingtype:    'Diagnostic testing',
      specimentype:            'Blood',
      collecteddate:           '09/01/2014',
      receiveddate:            '09/01/2014',
      authoriseddate:          '09/04/2014',
      genotype:                'MLH1: c.[1653dup];[=] p.[(Thr552fs)];[(=)]',
      genetictestscope:        'Colorectal cancer panel',
      karyotypingmethod:       'MLH1 MSH2 & MSH6' }.to_json
  end
end
