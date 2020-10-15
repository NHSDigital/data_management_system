require 'test_helper'
require 'import/genotype.rb'
require 'import/colorectal/core/genotype_mmr.rb'
require 'import/brca/core/provider_handler'
require 'import/storage_manager/persister'

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
  @logger.expects(:debug).with("NO MUTATION FOUND")
  @logger.expects(:debug).with('Negative genes are ["EPCAM", "MLH1", "MSH2", "MSH6"]')
  @logger.expects(:debug).with("SUCCESSFUL gene parse for EPCAM")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MLH1")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH2")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH6")
  assert_equal 4, @handler.process_gene_and_variant(@genotype, @record).size
  cdna_record = build_raw_record('pseudo_id1' => 'bob')
  cdna_record.raw_fields["gene"] = "MLH1"
  cdna_record.raw_fields["acmg_cdna"] = "NM_000179.2:c.2960C>T"
  cdna_record.raw_fields["acmg_protein_change"] = "p.Thr987Ile"
  @logger.expects(:debug).with("Found mutated gene MLH1")
  @logger.expects(:debug).with('Negative genes are ["EPCAM", "MSH2", "MSH6"]')
  @logger.expects(:debug).with("SUCCESSFUL gene parse for EPCAM")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH2")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH6")
  @logger.expects(:debug).with("SUCCESSFUL gene parse for MLH1")
  assert_equal 4, @handler.process_gene_and_variant(@genotype, cdna_record).size
  end
  
  test 'coding_variant' do
    cdna_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_record.raw_fields["gene"] = "MLH1"
    cdna_record.raw_fields["acmg_cdna"] = "NM_000179.2:c.2960C>T"
    cdna_record.raw_fields["acmg_protein_change"] = "p.Val717Alafs*18"
    genotypes = []
    mutated_gene = cdna_record.raw_fields['gene']
    all_genes = cdna_record.raw_fields['genes analysed'] unless cdna_record.raw_fields['genes analysed'].nil?
    dna_variant = cdna_record.raw_fields['acmg_cdna'] unless cdna_record.raw_fields['acmg_cdna'].nil?
    protein_variant = cdna_record.raw_fields['acmg_protein_change']
    @logger.expects(:debug).with("Found mutated gene MLH1")
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "MSH2", "MSH6"]')
    @logger.expects(:debug).with("SUCCESSFUL gene parse for EPCAM")
    @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH2")
    @logger.expects(:debug).with("SUCCESSFUL gene parse for MSH6")
    @logger.expects(:debug).with("SUCCESSFUL gene parse for MLH1")
    assert_equal 4, @handler.coding_variant(@genotype, genotypes, mutated_gene, dna_variant, protein_variant, all_genes).size
  end

  test 'exonic_variant' do
    exon_record = build_raw_record('pseudo_id1' => 'bob')
    exon_record.raw_fields["gene"] = "MLH1"
    exon_record.raw_fields["codingdnasequencechange"] = "MSH2 exon 11-16 deletion"
    genotypes = []
    mutated_gene = exon_record.raw_fields['gene']
    all_genes = exon_record.raw_fields['genes analysed'] unless exon_record.raw_fields['genes analysed'].nil?
    exonic_variant = exon_record.raw_fields['codingdnasequencechange'] unless exon_record.raw_fields['codingdnasequencechange'].nil?
    @logger.expects(:debug).with('Found mutated gene MLH1 for insertion deletion duplication')
    @logger.expects(:debug).with('Found mutated deletion for insertion deletion duplication')
    @logger.expects(:debug).with('Found exon(s) 11-16 for insertion deletion duplication')
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "MSH2", "MSH6"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    assert_equal 4, @handler.exonic_variant(@genotype, genotypes, mutated_gene, exonic_variant, all_genes).size
  end

  test 'negative_mutated_genes' do
    negative_record = build_raw_record('pseudo_id1' => 'bob')
    negative_record.raw_fields["gene"] = "MLH1"
    negative_record.raw_fields["codingdnasequencechange"] = "MSH2 exon 11-16 deletion"
    genotypes = []
    mutated_gene = negative_record.raw_fields['gene']
    all_genes = negative_record.raw_fields['genes analysed'] unless negative_record.raw_fields['genes analysed'].nil?
    @logger.expects(:debug).with('Negative genes are ["EPCAM", "MSH2", "MSH6"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    assert_equal 3, @handler.negative_mutated_genes(@genotype, genotypes, all_genes, mutated_gene).size
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
    { "lab no." => 'Laboratory',
      "family id" => '0000000',
      requesteddate: '2018-12-18 00:00:00',
      providercode: 'Provider Code',
      genetictestscope: 'COLORECTAL CANCER REPORT',
      collecteddate: '2012-06-28 00:00:00',
      receiveddate: '2012-06-29 00:00:00',
      authoriseddate: '2019-04-19 00:00:00',
      "sample in goshg2p" => 'xxxxxx',
      sex: 'F',
      "genes analysed" => 'EPCAM;MLH1;MSH2;MSH6',
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