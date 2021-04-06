require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class SheffieldHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Sheffield::SheffieldHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  private

  def build_raw_record(options = {})
    default_options = { 'pseudo_id1' => '',
                        'pseudo_id2' => '',
                        'encrypted_demog' => '',
                        'clinical.to_json' => clinical_json,
                        'encrypted_rawtext_demog' => '',
                        'rawtext_clinical.to_json' => rawtext_clinical_json }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  test 'add_test_scope_from_karyo_fullscreen' do
    @logger.expects(:debug).with('ADDED FULL_SCREEN TEST for: MLH1 MSH2 & MSH6')
    @handler.add_test_scope_from_karyo(@genotype, @record)
  end

  test 'add_test_scope_from_karyo_targeted' do
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.mapped_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    @logger.expects(:debug).with('ADDED TARGETED TEST for: R242.1 :: Predictive testing')
    @handler.add_test_scope_from_karyo(@genotype, targeted_record)
  end


  test 'add_colorectal_from_raw_test_full_screen' do
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1653dup')
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Thr552fs')
    @handler.add_colorectal_from_raw_test(@genotype, @record)
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1653dup')
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Thr552fs')
    raw_test = @handler.add_colorectal_from_raw_test(@genotype, @record)
    assert_equal 3, raw_test.size
  end

  test 'add_colorectal_from_normal_test_full_screen' do
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    normal_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normal_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    normal_fs_record.raw_fields['karyotypingmethod'] = 'Full panel'
    normal_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BMPR1A')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PTEN')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for SMAD4')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @handler.add_colorectal_from_raw_test(@genotype, normal_fs_record)
  end


  test 'add_colorectal_from_incomplete_test_full_screen' do
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    incomplete_fs_record = build_raw_record('pseudo_id1' => 'bob')
    incomplete_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    incomplete_fs_record.raw_fields['karyotypingmethod'] = 'MLH1 MSH2 & MSH6'
    incomplete_fs_record.raw_fields['genotype'] = 'Incomplete analysis - see below'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @handler.add_colorectal_from_raw_test(@genotype, incomplete_fs_record)
  end

  test 'add_colorectal_from_multiple_genes_full_screen' do
    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    multiplegenes_fs_record = build_raw_record('pseudo_id1' => 'bob')
    multiplegenes_fs_record.mapped_fields['genetictestscope'] = 'Colorectal cancer panel'
    multiplegenes_fs_record.raw_fields['karyotypingmethod'] = 'Full panel'
    multiplegenes_fs_record.raw_fields['genotype'] = '"SMAD4:c.[1573A>G];[=]  p.[(Ile525Val)];[(=)] MUTYH: c.[1014G>C ];[=]  p.[(Glu338His)];[(=)] -See below'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BMPR1A')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BMPR1A')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: PTEN')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PTEN')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: STK11')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for SMAD4')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.add_colorectal_from_raw_test(@genotype, multiplegenes_fs_record)
  end

  test 'add_colorectal_from_multiple_genes_karyofield_full_screen' do

    @genotype.attribute_map['genetictestscope'] = 'Full screen Colorectal Lynch or MMR'
    normalmultiplekaryo_fs_record = build_raw_record('pseudo_id1' => 'bob')
    normalmultiplekaryo_fs_record.mapped_fields['genetictestscope'] = 'R209 :: Inherited colorectal cancer (with or without polyposis)'
    normalmultiplekaryo_fs_record.raw_fields['karyotypingmethod'] = 'R209.1 :: NGS - APC and MUTYH only'
    normalmultiplekaryo_fs_record.raw_fields['genotype'] = 'No pathogenic mutation detected'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.add_colorectal_from_raw_test(@genotype, normalmultiplekaryo_fs_record)
  end
  
  
  test 'add_colorectal_from_raw_test_targeted' do

    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.mapped_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    targeted_record.raw_fields['genotype'] = 'c.[2079dup];[2079=]  p.[(Cys694fs)];[(Cys694=)] MSH6 '
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 2079dup')
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Cys694fs')
    @handler.add_colorectal_from_raw_test(@genotype, targeted_record)
  end

  test 'add_colorectal_from_null_test_targeted' do
    @genotype.attribute_map['genetictestscope'] = 'Targeted Colorectal Lynch or MMR'
    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.mapped_fields['genetictestscope'] = 'R210 :: Inherited MMR deficiency (Lynch syndrome)'
    targeted_record.raw_fields['karyotypingmethod'] = 'R242.1 :: Predictive testing'
    targeted_record.raw_fields['genotype'] = 'Familial likely pathogenic mutation NOT detected'
    @logger.expects(:error).with('Bad input type given for colorectal extraction: ')
    @handler.add_colorectal_from_raw_test(@genotype, targeted_record)
    @logger.expects(:error).with('Bad input type given for colorectal extraction: ')
    assert_equal 1, @handler.add_colorectal_from_raw_test(@genotype, targeted_record)[0].attribute_map['teststatus']
  end

  test 'process_teststatus' do
    @handler.process_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 1653dup')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 'c.1653dup', @genotype.attribute_map['codingdnasequencechange']
  end

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
