require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class OxfordHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Oxford::OxfordHandlerColorectal.new(EBatch.new)
    end

    @logger = Import::Log.get_logger
  end

  test 'assign_test_scope' do
    @handler.assign_test_scope(@genotype, @record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['scope / limitations of test'] = 'Cabbage'
    @logger.expects(:debug).with('Unable to parse genetic test scope')
    @handler.assign_test_scope(@genotype, broken_record)

    targeted_record = build_raw_record('pseudo_id1' => 'bob')
    targeted_record.raw_fields['scope / limitations of test'] = 'Targeted'
    @handler.assign_test_scope(@genotype, targeted_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    ashkenazi_record = build_raw_record('pseudo_id1' => 'bob')
    ashkenazi_record.raw_fields['scope / limitations of test'] = 'Ashkenazi'
    @handler.assign_test_scope(@genotype, ashkenazi_record)
    assert_equal 'AJ Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']

    polish_record = build_raw_record('pseudo_id1' => 'bob')
    polish_record.raw_fields['scope / limitations of test'] = 'Polish'
    @handler.assign_test_scope(@genotype, polish_record)
    assert_equal 'Polish Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'assign_method' do
    @handler.assign_method(@genotype, @record)
    assert_equal 17, @genotype.attribute_map['karyotypingmethod']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['karyotypingmethod'] = 'Cabbage'
    @logger.expects(:warn).with('Unknown method: Cabbage; possibly need to update map')
    @handler.assign_method(@genotype, broken_record)
  end

  test 'process_records' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 7638_7646del')
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Arg2547_Ser2549del')
    @handler.process_records(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['gene'] = 'Cabbage'
    assert_equal 0, @handler.process_records(@genotype, broken_record).size
  end

  test 'process_gene' do
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: MSH2')
    @handler.process_gene(@record, @genotype, genotypes)

    mutyh_record = build_raw_record('pseudo_id1' => 'bob')
    mutyh_record.raw_fields['gene'] = 'MutYH'
    mutyh_genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: MutYH')
    @handler.process_gene(mutyh_record, @genotype, mutyh_genotypes)

    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['gene'] = 'Cabbage'
    broken_genotypes = []
    @logger.expects(:debug).with('Failed gene parse')
    @handler.process_gene(broken_record, @genotype, broken_genotypes)
  end

  test 'assign_servicereportidentifier' do
    @handler.assign_servicereportidentifier(@genotype, @record)
    assert_equal '123456', @genotype.attribute_map['servicereportidentifier']
  end

  test 'process_protein_impact' do
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Arg2547_Ser2549del')
    @handler.process_protein_impact(@record, @genotype, genotypes)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['proteinimpact'] = 'Cabbage'
    broken_genotypes = []
    @logger.expects(:debug).with('FAILED protein change parse')
    @handler.process_protein_impact(broken_record, @genotype, broken_genotypes)
  end

  test 'process_cdna_change' do
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 7638_7646del')
    @handler.process_cdna_change(@record, @genotype, genotypes)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['codingdnasequencechange'] = 'Cabbage'
    broken_genotypes = []
    @logger.expects(:debug).with('FAILED cdna change parse')
    @handler.process_cdna_change(broken_record, @genotype, broken_genotypes)
    chromosome_record = build_raw_record('pseudo_id1' => 'bob')
    chromosome_record.raw_fields['codingdnasequencechange'] = 'Insertion Exon 10'
    chromosome_genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL chromosomal variant parse for: Ins')
    @handler.process_cdna_change(chromosome_record, @genotype, chromosome_genotypes)
  end

  test 'assign_genomic_change' do
    @handler.assign_genomic_change(@genotype, @record)
    assert_equal '11:108202614_108202622', @genotype.attribute_map['genomicchange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = 'Cabbage'
    @logger.expects(:warn).with('Could not process, so adding raw genomic change: Cabbage')
    @handler.assign_genomic_change(@genotype, broken_record)
  end

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_to_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_to_clinical_to_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_to_json
    { sex: '1',
      consultantcode: 'ConsultantCode',
      providercode: 'ProviderCode',
      servicereportidentifier: '123456',
      sortdate: '2017-10-25T00:00:00.000+01:00',
      karyotypingmethod: '17',
      specimentype: '5',
      gene: '2804',
      referencetranscriptid: 'NM_000051.3',
      genomicchange: 'Chr11.hg19:g.108202614_108202622',
      codingdnasequencechange: 'c.[7638_7646del]+[=]',
      proteinimpact: 'p.[Arg2547_Ser2549del]+[=]',
      variantpathclass: '5: Clearly pathogenic',
      age: 999 } .to_json
  end

  def rawtext_to_clinical_to_json
    { sex: 'Male',
      providercode: 'Oxford Centre for Genomic Medicine',
      consultantname: 'Ms Subhashini Balasingham',
      investigationid: '123456',
      'service level' => 'routine',
      collceteddate: '',
      requesteddate: '2017-10-25 00:00:00',
      receiveddate: '2014-11-27 00:00:00',
      authoriseddate: '2018-01-18 00:00:00',
      moleculartestingtype: 'diagnostic',
      'scope / limitations of test' => 'Full screen',
      gene: 'MSH2',
      referencetranscriptid: 'NM_000051.3',
      genomicchange: 'Chr11.hg19:g.108202614_108202622',
      codingdnasequencechange: 'c.[7638_7646del]+[=]',
      proteinimpact: 'p.[Arg2547_Ser2549del]+[=]',
      variantpathclass: '5: Clearly pathogenic',
      'clinical implications / conclusions' => 'Pathogenic in AT but may represent lower penetrance in cancer predisposition',
      specimentype: 'BLOOD',
      karyotypingmethod: 'Sequencing, Next Generation Panel (NGS)',
      'origin of mutation / rearrangement' => '',
      'percentage mutation allele / abnormal karyotype' => '',
      sinonym: '' }.to_json
  end
end
