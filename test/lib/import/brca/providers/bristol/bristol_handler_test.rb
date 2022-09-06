require 'test_helper'

class BristolHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Bristol::BristolHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
    # @logger.level = Logger::WARN
  end

  PROTEIN_REGEX = /p.(?:\((?<impact>.*)\))/

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_cdna_change' do
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    assert_equal 'c.8167G>C', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'process_mutated_and_normal_gene' do
    @handler.process_cdna_change(@genotype, @record)
    res = @handler.process_gene(@genotype, @record)
    assert_equal 2, res.size
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 2, res[1].attribute_map['teststatus']
  end

  test 'process_normal_record' do
    normal_record = build_raw_record('pseudo_id1' => 'bob')
    normal_record.raw_fields['variantpathclass'] = 'Benign'
    @handler.process_test_status(@genotype, normal_record)
    res = @handler.process_gene(@genotype, normal_record)
    assert_equal 2, res.size
    assert_equal 1, res[0].attribute_map['teststatus']
    assert_equal 1, res[1].attribute_map['teststatus']
  end

  test 'process_protein_impact' do
    @handler.add_protein_impact(@genotype, @record)
    assert_equal 'p.Asp2723His', @genotype.attribute_map['proteinimpact']
  end

  test 'process_genomic_change' do
    @handler.process_genomic_change(@genotype, @record)
    assert_equal '13:32937506', @genotype.attribute_map['genomicchange']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.raw_fields['genomicchange'] = '13: 32937506'
    @logger.expects(:warn).with('Could not process genomic change, adding raw: 13: 32937506')
    @handler.process_genomic_change(@genotype, broken_record)
  end

  private

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2015-05-06T00: 00: 00.000+01: 00',
      authoriseddate: '2015-07-01T00: 00: 00.000+01: 00',
      servicereportidentifier: 'Service Report Identifier',
      requesteddate: '2015-05-07',
      genomicchange: '13:32937506',
      gene: '8',
      referencetranscriptid: 'NM_000059.3',
      codingdnasequencechange: 'c.8167G>C',
      proteinimpact: 'p.Asp2723His',
      variantpathclass: 'Deleterious',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      consultantname: 'Consultant Name',
      providercode: 'Provider Address',
      receiveddate: '2015-05-06 00: 00: 00',
      requesteddate: '2015-05-07 00: 00: 00',
      authoriseddate: '2015-07-01 00: 00: 00',
      servicereportidentifier: 'Service Report Identifier',
      genomicchange: '13:32937506',
      gene: 'BRCA2',
      referencetranscriptid: 'NM_000059.3',
      codingdnasequencechange: 'c.8167G>C',
      proteinimpact: 'p.Asp2723His',
      rs: 'rs41293511',
      'times observed per panel group' => '1',
      variantpathclass: 'Deleterious' }.to_json
  end
end
