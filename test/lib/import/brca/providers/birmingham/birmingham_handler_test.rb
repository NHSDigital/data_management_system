require 'test_helper'
#require 'import/genotype.rb'
#require 'import/brca/core/provider_handler'

class BirminghamHandlerTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Birmingham::BirminghamHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  PROTEIN_REGEX = /p.(?:\((?<impact>.*)\))/ .freeze

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_genomic_change' do
    @handler.process_genomic_change(@genotype, @record)
    assert_equal '17:41197784G>A', @genotype.attribute_map['genomicchange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = 'genomicchange'
    @logger.expects(:warn).with('Genomic change did not match expected format,adding raw: genomicchange')
    @handler.process_genomic_change(@genotype, broken_record)
    null_record = build_raw_record('pseudo_id1' => 'bob')
    null_record.raw_fields['genomicchange'] = nil
    @logger.expects(:warn).with('Genomic change was empty')
    @handler.process_genomic_change(@genotype, null_record)
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 5503C>T')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 'c.5503C>T', @genotype.attribute_map['codingdnasequencechange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['codingdnasequencechange'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED cdna change parse for: Cabbage')
    @handler.process_cdna_change(@genotype, broken_record)
  end

  test 'process_impact' do
    @handler.process_impact(@genotype, @record)
    assert_equal 'p.Arg1835Ter', @genotype.attribute_map['proteinimpact']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['proteinimpact'] = 'Cabbage'
    @logger.expects(:warn).with('Could not parse impact: Cabbage')
    @handler.process_impact(@genotype, broken_record)
  end

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
    { sex: '2',
      receiveddate: '2012-06-28T00:00:00.000+01:00',
      authoriseddate: '2012-08-28T00:00:00.000+01:00',
      genetictestscope: 'Diagnosis',
      gene: '7',
      referencetranscriptid: 'NM_007294.3',
      genomicchange: 'NC_000017.10:g.41197784G\u003eA',
      codingdnasequencechange: 'c.5503C>T',
      proteinimpact: 'p.(Arg1835*)',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { moleculartestingtype: 'Diagnosis',
      gene: 'BRCA1',
      referencetranscriptid: 'NM_007294.3',
      genomicchange: 'NC_000017.10:g.41197784G>A',
      codingdnasequencechange: 'c.5503C>T',
      proteinimpact: 'p.(Arg1835*)',
      authoriseddate: '28/08/2012',
      sex: 'F',
      receiveddate: '28/06/2012' }.to_json
  end
end
