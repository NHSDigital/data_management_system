require 'test_helper'

class LondonKgcHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = LondonKgc::LondonKgcHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'process_cdna_change' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 697G>A')
    @handler.process_cdna_change(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
    nomutation_record = build_raw_record('pseudo_id1' => 'bob')
    nomutation_record.mapped_fields['genotype'] = 'No mutation detected'
    @logger.expects(:debug).with('No mutation detected')
    @handler.process_cdna_change(@genotype, nomutation_record)
    assert_equal 1, @genotype.attribute_map['teststatus']
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['genotype'] = 'Cabbage'
    @logger.expects(:debug).with('Impossible to parse cdna change')
    @handler.process_cdna_change(@genotype, broken_record)
  end

  test 'process_gene' do
    @logger.expects(:debug).with('Successful parse for BRCA1')
    @handler.process_gene(@genotype, @record)
    assert_equal 7, @genotype.attribute_map['gene']
    nogene_record = build_raw_record('pseudo_id1' => 'bob')
    nogene_record.mapped_fields['genotype'] = 'Cabbage c.666A>O'
    @logger.expects(:debug).with('No gene detected')
    @handler.process_gene(@genotype, nogene_record)
  end

  test 'process_varpathclass' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 3')
    @handler.process_varpathclass(@genotype, @record)
    assert_equal 3, @genotype.attribute_map['variantpathclass']
  end

  test 'process_exons' do
    @handler.process_exons(@genotype, @record)
    assert_nil @genotype.attribute_map['variantlocation']
    assert_nil @genotype.attribute_map['sequencevarianttype']
    exon_record = build_raw_record('pseudo_id1' => 'bob')
    exon_record.mapped_fields['genotype'] = 'BRCA1 exon 22 deletion'
    @logger.expects(:debug).with('SUCCESSFUL exon parse for: BRCA1 exon 22 deletion')
    @handler.process_exons(@genotype, exon_record)
    assert_equal 1, @genotype.attribute_map['variantlocation']
    assert_equal 3, @genotype.attribute_map['sequencevarianttype']
  end

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
      providercode: 'R1K01',
      collecteddate: '2015-11-11T00:00:00.000+00:00',
      receiveddate: '2015-11-11T00:00:00.000+00:00',
      authoriseddate: '2015-12-08T00:00:00.000+00:00',
      servicereportidentifier: '0012G012345',
      specimentype: '5',
      genotype: 'BRCA1 c.697G>A p.(Val233Ile)',
      variantpathclass: '3 - uncertain',
      age: 34 }.to_json
  end

  def rawtext_clinical_json
    { genotype: 'BRCA1 c.697G>A p.(Val233Ile)',
      variantpathclass: '3 - uncertain',
      'test type 1': 'Next Gen Sequencing',
      'test type 2': '',
      sex: 'F',
      'clinician desc': 'Some Body',
      consultantcode: nil,
      'specialty desc': 'CLINICAL GENETICS',
      providercode: 'NW Thames Regional Genetics Service',
      'source desc': 'NWTRGS - KENNEDY-GALTON CENTRE',
      'source ccg desc': 'NHS EALING CCG',
      servicereportidentifier: '0012G012345',
      specimentype: 'Blood',
      collecteddate: '2015-11-11 00:00:00',
      receiveddate: '2015-11-11 00:00:00',
      authoriseddate: '2015-12-08 00:00:00',
      'all clinical comments (semi colon separated).all clinical comment text': 'Breast Cancer;Trusight Cancer panel' }.to_json
  end
end
