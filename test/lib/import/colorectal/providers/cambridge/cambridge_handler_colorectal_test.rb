require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class CambridgeHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Cambridge::CambridgeHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 2529_2530delTG')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['codingdnasequencechange'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED cdna change parse for: Cabbage')
    @handler.process_cdna_change(@genotype, broken_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'add_protein_impact' do
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Ala844Ter')
    @handler.add_protein_impact(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['proteinimpact'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED protein change parse for: Cabbage')
    @handler.add_protein_impact(@genotype, broken_record)
  end

  test 'process_genomic_change' do
    @logger.expects(:debug).with('SUCCESSFUL chromosome change parse for: 2 and 47707905_47707906delTG')
    @handler.process_genomic_change(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = nil
    @logger.expects(:warn).with('Genomic change was empty')
    @handler.process_genomic_change(@genotype, broken_record)
    assert_nil @genotype.attribute_map['gene']
    raw_gen_change_record = build_raw_record('pseudo_id1' => 'bob')
    raw_gen_change_record.raw_fields['genomicchange'] = 'NC_000002.11:g'
    expected_msg = 'Genomic change did not match expected format,adding raw: NC_000002.11:g'
    @logger.expects(:warn).with(expected_msg)
    @handler.process_genomic_change(@genotype, raw_gen_change_record)
  end

  test 'process_gene' do
    @logger.expects(:debug).with('No detected genes given for colorectal cancers extraction: Cabbage')
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['gene'] = 'Cabbage'
    @handler.process_gene(@genotype, broken_record)
    assert_nil @genotype.attribute_map['gene']
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @handler.process_gene(@genotype, @record)
    assert_equal 2804, @genotype.attribute_map['gene']
  end

  test 'add_zygosity' do
    @logger.expects(:debug).with('SUCCESSFUL zygosity parse for: 0/1')
    @handler.add_zygosity(@genotype, @record)
    assert_equal 1, @genotype.attribute_map['variantgenotype']
    homo_record = build_raw_record('pseudo_id1' => 'bob')
    homo_record.raw_fields['variantgenotype'] = '0/0'
    @logger.expects(:debug).with('SUCCESSFUL zygosity parse for: 0/0')
    @handler.add_zygosity(@genotype, homo_record)
    assert_equal 2, @genotype.attribute_map['variantgenotype']
    broken_record_zygo = build_raw_record('pseudo_id1' => 'bob')
    broken_record_zygo.raw_fields['variantgenotype'] = 'Cabbage'
    @logger.expects(:debug).with('Cannot determine zygosity; perhaps should be complex? Cabbage')
    @handler.add_zygosity(@genotype, broken_record_zygo)
  end

  test 'process_exons' do
    @logger.expects(:warn).with('Cannot extract exon from: NP_000242.1:p.(Ala844Ter)')
    @handler.process_exons(@record.raw_fields['proteinimpact'], @genotype)
    broken_record_zygo = build_raw_record('pseudo_id1' => 'bob')
    broken_record_zygo.raw_fields['proteinimpact'] = 'Deletion of exon 8 on MLPA'
    expected_msg = 'SUCCESSFUL exon extraction for: deletion of exon 8 on mlpa'
    @logger.expects(:debug).with(expected_msg)
    @handler.process_exons(broken_record_zygo.raw_fields['proteinimpact'].downcase, @genotype)
    assert_equal '8', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
  end

  # TODO: write test coverage for function 'summarize'

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

  def clinical_json
    { sex: '1',
      consultantcode: 'C4567890',
      authoriseddate: '2010-08-19T00:00:00.000+01:00',
      sortdate: '2010-07-12T00:00:00.000+01:00',
      specimentype: '5',
      gene: '2804',
      requesteddate: '2010-07-12T00:00:00.000+01:00',
      age: 52 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'M',
      providercode: 'Clinical Genetics',
      consultantname: 'Firstname SURNAME',
      servicereportidentifier: 'GM12.3456',
      status: 'NHS',
      gene: 'MSH2',
      referencetranscriptid: 'NM_000251.2',
      genomicchange: 'NC_000002.11:g.47707905_47707906delTG',
      codingdnasequencechange: 'NM_000251.2:c.2529_2530delTG',
      proteinimpact: 'NP_000242.1:p.(Ala844Ter)',
      variantgenotype: '0/1',
      variantpathclass: '5',
      requesteddate: '12/07/2010',
      authoriseddate: '19/08/2010',
      specimentype: 'Blood' }.to_json
  end
end
