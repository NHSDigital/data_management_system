require 'test_helper'

class CambridgeHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Cambridge::CambridgeHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 7994A>G')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['codingdnasequencechange'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED cdna change parse for: Cabbage')
    @handler.process_cdna_change(@genotype, broken_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
  end

  test 'add_protein_impact' do
    @logger.expects(:debug).with('SUCCESSFUL protein change parse for: Asp2665Gly')
    @handler.add_protein_impact(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['proteinimpact'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED protein change parse for: Cabbage')
    @handler.add_protein_impact(@genotype, broken_record)
  end

  test 'process_genomic_change' do
    @logger.expects(:debug).with('SUCCESSFUL chromosome change parse for: 13 and 40038523')
    @handler.process_genomic_change(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = nil
    @logger.expects(:warn).with('Genomic change was empty')
    @handler.process_genomic_change(@genotype, broken_record)
    assert_nil @genotype.attribute_map['gene']
    raw_gen_change_record = build_raw_record('pseudo_id1' => 'bob')
    raw_gen_change_record.raw_fields['genomicchange'] = 'NC_000013.10:g'
    expected_msg = 'Genomic change did not match expected format,adding raw: NC_000013.10:g'
    @logger.expects(:warn).with(expected_msg)
    @handler.process_genomic_change(@genotype, raw_gen_change_record)
  end

  test 'process_gene' do
    @logger.expects(:debug).with('FAILED gene parse for: 0')
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['gene'] = 'Cabbage'
    @handler.process_gene(@genotype, broken_record)
    assert_nil @genotype.attribute_map['gene']
    @logger.expects(:debug).with('SUCCESSFUL gene parse for 8')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for: 8')
    @handler.process_gene(@genotype, @record)
    assert_equal 8, @genotype.attribute_map['gene']
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
    @logger.expects(:warn).with('Cannot extract exon from: NP_000050.2:p.(Asp2665Gly)')
    @handler.process_exons(@record.raw_fields['proteinimpact'], @genotype)
    broken_record_zygo = build_raw_record('pseudo_id1' => 'bob')
    broken_record_zygo.raw_fields['proteinimpact'] = 'Heterozygous deletion of exons 14-16 on MLPA'
    expected_msg = 'SUCCESSFUL exon extraction for: Heterozygous deletion of exons 14-16 on MLPA'
    @logger.expects(:debug).with(expected_msg)
    @handler.process_exons(broken_record_zygo.raw_fields['proteinimpact'], @genotype)
    assert_equal '14-16', @genotype.attribute_map['exonintroncodonnumber']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
  end

  # TODO: write test coverage for function 'summarize'

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_clinical_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { sex: '1',
      consultantcode: 'Consultant Code',
      authoriseddate: '2017-08-17T00:00:00.000+01:00',
      sortdate: '2017-07-31T00:00:00.000+01:00',
      specimentype: '5',
      gene: '8',
      requesteddate: '2017-07-31T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'M',
      providercode: 'Provider Address',
      consultantname: 'Consultant Name',
      servicereportidentifier: 'Service Report Identifier',
      status: 'NHS',
      gene: 'BRCA2',
      referencetranscriptid: 'NM_000059.3',
      genomicchange: 'NC_000013.10:g.40038523',
      codingdnasequencechange: 'NM_000059.3:c.7994A>G',
      proteinimpact: 'NP_000050.2:p.(Asp2665Gly)',
      variantgenotype: '0/1',
      variantpathclass: '0',
      requesteddate: '31/07/2017',
      authoriseddate: '17/08/2017',
      specimentype: 'Blood' }.to_json
  end
end
