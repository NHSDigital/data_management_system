require 'test_helper'

class LondonGoshHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::LondonGosh::LondonGoshHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_gene_and_variant' do
    @logger.expects(:debug).with('NO MUTATION FOUND')
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA1", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    normal_genes = @handler.process_gene_and_variant(@genotype, @record)
    assert_equal 4, normal_genes.size
    cdna_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_record.raw_fields['gene'] = 'BRCA1'
    cdna_record.raw_fields['acmg_cdna'] = 'NM_000179.2:c.2960C>T'
    cdna_record.raw_fields['acmg_protein_change'] = 'p.Thr987Ile'
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    cdna_mutations = @handler.process_gene_and_variant(@genotype, cdna_record)
    assert_equal 4, cdna_mutations.size
    assert_equal 2, cdna_mutations[3].attribute_map['teststatus']
    assert_equal 4, cdna_mutations[3].attribute_map['variantpathclass']
    assert_nil(cdna_mutations[0].attribute_map['variantpathclass'])
    assert_nil(cdna_mutations[1].attribute_map['variantpathclass'])
    assert_nil(cdna_mutations[2].attribute_map['variantpathclass'])
  end

  test 'coding_variant' do
    acmg_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    acmg_cdna_record.raw_fields['gene'] = 'BRCA1'
    acmg_cdna_record.raw_fields['acmg_cdna'] = 'NM_000179.2:c.2960C>T'
    acmg_cdna_record.raw_fields['acmg_protein_change'] = 'p.Val717Alafs*18'
    acmg_cdna_record.raw_fields['codingdnasequencechange'] = ''
    acmg_cdna_record.raw_fields['proteinimpact'] = ''
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    cdna_mutations = @handler.process_gene_and_variant(@genotype, acmg_cdna_record)
    assert_equal 4, cdna_mutations.size
    assert_equal 2, cdna_mutations[3].attribute_map['teststatus']
    coding_cdna_record = build_raw_record('pseudo_id1' => 'bob')
    coding_cdna_record.raw_fields['gene'] = 'BRCA1'
    coding_cdna_record.raw_fields['acmg_cdna'] = nil
    coding_cdna_record.raw_fields['acmg_protein_change'] = nil
    coding_cdna_record.raw_fields['codingdnasequencechange'] = 'NM_000179.2:c.2960C>T'
    coding_cdna_record.raw_fields['proteinimpact'] = 'p.Val717Alafs*18'
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    codingcdna_mutations = @handler.process_gene_and_variant(@genotype, coding_cdna_record)
    assert_equal 4, codingcdna_mutations.size
    assert_equal 2, codingcdna_mutations[3].attribute_map['teststatus']
    assert_equal 'c.2960C>T', codingcdna_mutations[3].attribute_map['codingdnasequencechange']
  end

  test 'exonic_variant' do
    exon_record = build_raw_record('pseudo_id1' => 'bob')
    exon_record.raw_fields['gene'] = 'BRCA1'
    exon_record.raw_fields['codingdnasequencechange'] = 'BRCA1 exon 11-16 deletion'
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    exon_mutations = @handler.process_gene_and_variant(@genotype, exon_record)
    assert_equal 4, exon_mutations.size
    assert_equal 2, exon_mutations[3].attribute_map['teststatus']
    assert_equal '11-16', exon_mutations[3].attribute_map['exonintroncodonnumber']
  end

  test 'negative_genes' do
    @logger.expects(:debug).with('NO MUTATION FOUND')
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "BRCA1", "BRCA2", "RAD51C"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for RAD51C')
    normal_genes = @handler.process_gene_and_variant(@genotype, @record)
    assert_equal 4, normal_genes.size
    assert_equal 1, normal_genes[0].attribute_map['teststatus']
    assert_equal 1, normal_genes[1].attribute_map['teststatus']
    assert_equal 1, normal_genes[2].attribute_map['teststatus']
    assert_equal 1, normal_genes[3].attribute_map['teststatus']
    assert_nil(normal_genes[0].attribute_map['variantpathclass'])
    assert_nil(normal_genes[1].attribute_map['variantpathclass'])
    assert_nil(normal_genes[2].attribute_map['variantpathclass'])
    assert_nil(normal_genes[3].attribute_map['variantpathclass'])
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'RP401',
      collecteddate: '2012-06-28T00: 00: 00.000+01: 00',
      receiveddate: '2012-06-29T00: 00: 00.000+01: 00',
      authoriseddate: '2019-04-19T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      genetictestscope: 'BRCA CANCER REPORT',
      requesteddate: '2018-12-18T00: 00: 00.000+00: 00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { 'lab no.' => 'Laboratory',
      'family id' => '0000000',
      requesteddate: '2018-12-18 00:00:00',
      providercode: 'Provider Code',
      genetictestscope: 'BRCA CANCER REPORT',
      collecteddate: '2012-06-28 00:00:00',
      receiveddate: '2012-06-29 00:00:00',
      authoriseddate: '2019-04-19 00:00:00',
      'sample in goshg2p' => 'xxxxxx',
      sex: 'F',
      'genes analysed' => 'EPCAM;BRCA1;BRCA2;RAD51C',
      gene: '',
      codingdnasequencechange: '',
      proteinimpact: '',
      variantpathclass: '',
      acmg_classification: '4',
      acmg_cdna: '',
      acmg_protein_change: '',
      acmg_evidence: '' }.to_json
  end
end
