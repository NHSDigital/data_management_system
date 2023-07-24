require 'test_helper'
# require 'import/genotype.rb'
# require 'import/colorectal/core/genotype_mmr.rb'
# require 'import/brca/core/provider_handler'
# require 'import/storage_manager/persister'

class LondonGoshHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::LondonGosh::LondonGoshHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_gene_and_variant' do
    genocolorectals = @handler.process_gene_and_variant(@genotype, @record)
    assert_equal 4, genocolorectals.size
    assert_equal 1432, genocolorectals[0].attribute_map['gene']
    assert_equal 2744, genocolorectals[1].attribute_map['gene']
    assert_equal 2804, genocolorectals[2].attribute_map['gene']
    assert_equal 2808, genocolorectals[3].attribute_map['gene']
    # all are test status 1
    assert_equal [1], genocolorectals.collect(&:attribute_map).pluck('teststatus').uniq
    cdna_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_record.raw_fields['gene'] = 'MLH1'
    cdna_record.raw_fields['acmg_cdna'] = 'NM_000179.2:c.2960C>T'
    cdna_record.raw_fields['acmg_protein_change'] = 'p.Thr987Ile'
    cdna_record.raw_fields['acmg_classification'] = '5'
    genocolorectals_pos = @handler.process_gene_and_variant(@genotype, cdna_record)
    assert_equal 4, genocolorectals_pos.size
    assert_equal 1432, genocolorectals_pos[0].attribute_map['gene']
    assert_equal 2804, genocolorectals_pos[1].attribute_map['gene']
    assert_equal 2808, genocolorectals_pos[2].attribute_map['gene']
    # MLH1 is positive now and assigned varpathclass
    assert_equal 2744, genocolorectals_pos[3].attribute_map['gene']
    assert_equal 2, genocolorectals_pos[3].attribute_map['teststatus']
    assert_equal 5, genocolorectals_pos[3].attribute_map['variantpathclass']
    assert_equal 'c.2960C>T', genocolorectals_pos[3].attribute_map['codingdnasequencechange']
    assert_equal 'p.Thr987Ile', genocolorectals_pos[3].attribute_map['proteinimpact']
  end

  test 'coding_variant' do
    cdna_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_record.raw_fields['gene'] = 'MLH1'
    cdna_record.raw_fields['acmg_cdna'] = 'NM_000179.2:c.2960C>T'
    cdna_record.raw_fields['acmg_protein_change'] = 'p.Val717Alafs*18'
    genotypes = []
    mutated_gene = cdna_record.raw_fields['gene']
    unless cdna_record.raw_fields['genes analysed'].nil?
      all_genes = cdna_record.raw_fields['genes analysed']
    end
    unless cdna_record.raw_fields['acmg_cdna'].nil?
      dna_variant = cdna_record.raw_fields['acmg_cdna']
    end
    protein_variant = cdna_record.raw_fields['acmg_protein_change']
    @handler.coding_variant(@genotype, genotypes, mutated_gene, dna_variant, protein_variant, all_genes)
    assert_equal 4, genotypes.size
    assert_equal 1432, genotypes[0].attribute_map['gene']
    assert_equal 2804, genotypes[1].attribute_map['gene']
    assert_equal 2808, genotypes[2].attribute_map['gene']
    # MLH1 is positive
    assert_equal 2744, genotypes[3].attribute_map['gene']
    assert_equal 'c.2960C>T', genotypes[3].attribute_map['codingdnasequencechange']
    assert_equal 'p.Val717AlafsTer18', genotypes[3].attribute_map['proteinimpact']
    assert_equal 2, genotypes[3].attribute_map['teststatus']
  end

  test 'exonic_variant' do
    exon_record = build_raw_record('pseudo_id1' => 'bob')
    exon_record.raw_fields['gene'] = 'MLH1'
    exon_record.raw_fields['codingdnasequencechange'] = 'MLH1 exon 11-16 deletion'
    genotypes = []
    mutated_gene = exon_record.raw_fields['gene']
    unless exon_record.raw_fields['genes analysed'].nil?
      all_genes = exon_record.raw_fields['genes analysed']
    end
    unless exon_record.raw_fields['codingdnasequencechange'].nil?
      exonic_variant = exon_record.raw_fields['codingdnasequencechange']
    end
    @handler.exonic_variant(@genotype, genotypes, mutated_gene, exonic_variant, all_genes)
    assert_equal 4, genotypes.size
    assert_equal 1432, genotypes[0].attribute_map['gene']
    assert_equal 2804, genotypes[1].attribute_map['gene']
    assert_equal 2808, genotypes[2].attribute_map['gene']
    # MLH1 is positive
    assert_equal 2744, genotypes[3].attribute_map['gene']
    assert_equal '11-16', genotypes[3].attribute_map['exonintroncodonnumber']
    assert_equal 2, genotypes[3].attribute_map['teststatus']
  end

  test 'negative_mutated_genes' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields['gene'] = 'MLH1'
    negative_record.raw_fields['codingdnasequencechange'] = 'MLH1 exon 11-16 deletion'
    genotypes = []
    mutated_gene = negative_record.raw_fields['gene']
    unless negative_record.raw_fields['genes analysed'].nil?
      all_genes = negative_record.raw_fields['genes analysed']
    end
    @handler.negative_mutated_genes(@genotype, genotypes, all_genes, mutated_gene)
    assert_equal 3, genotypes.size
    assert_equal 1432, genotypes[0].attribute_map['gene']
    assert_equal 2804, genotypes[1].attribute_map['gene']
    assert_equal 2808, genotypes[2].attribute_map['gene']
    # All marked as test status 1
    assert_equal [1], genotypes.collect(&:attribute_map).pluck('teststatus').uniq
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'RP401',
      collecteddate: '2012-06-28T00: 00: 00.000+01: 00',
      receiveddate: '2012-06-29T00: 00: 00.000+01: 00',
      authoriseddate: '2019-04-19T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      genetictestscope: 'COLORECTAL CANCER REPORT',
      requesteddate: '2018-12-18T00: 00: 00.000+00: 00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { 'lab no.' => 'Laboratory',
      'family id' => '0000000',
      requesteddate: '2018-12-18 00:00:00',
      providercode: 'Provider Code',
      genetictestscope: 'COLORECTAL CANCER REPORT',
      collecteddate: '2012-06-28 00:00:00',
      receiveddate: '2012-06-29 00:00:00',
      authoriseddate: '2019-04-19 00:00:00',
      'sample in goshg2p' => 'xxxxxx',
      sex: 'F',
      'genes analysed' => 'EPCAM;MLH1;MSH2;MSH6',
      gene: '',
      codingdnasequencechange: '',
      proteinimpact: '',
      variantpathclass: '',
      acmg_classification: '',
      acmg_cdna: '',
      acmg_protein_change: '',
      acmg_evidence: '' }.to_json
  end
end
