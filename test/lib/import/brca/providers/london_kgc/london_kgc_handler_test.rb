require 'test_helper'

class LondonKgcHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::LondonKgc::LondonKgcHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process record with no mutation' do
    nomutation_record = build_raw_record('pseudo_id1' => 'bob')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, nomutation_record)
    assert_equal 3, genotypes.size
  end

  test 'process protein impact' do
    roundbrackets_record = build_raw_record('pseudo_id1' => 'bob')
    roundbrackets_record.raw_fields['genotype'] = 'BRCA2 c.2836_2837delGA; p.(Asp946Phefs*12)'
    @logger.expects(:debug).with('Found dna mutation in ["BRCA2"] GENE(s) in position [["c.2836_2837delGA"]] with impact [["Asp946Phefs*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: BRCA2, c.2836_2837delGA, Asp946Phefs*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA1", "TP53"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, roundbrackets_record)
    assert_equal 'p.Asp946PhefsTer', genotypes[0].attribute_map['proteinimpact']
    squarebrackets_record = build_raw_record('pseudo_id1' => 'bob')
    squarebrackets_record.raw_fields['genotype'] = 'BRCA2 c.2836_2837delGA; p.[Asp669Phefs*12]'
    @logger.expects(:debug).with('Found dna mutation in ["BRCA2"] GENE(s) in position [["c.2836_2837delGA"]] with impact [["Asp669Phefs*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: BRCA2, c.2836_2837delGA, Asp669Phefs*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA1", "TP53"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, squarebrackets_record)
    assert_equal 'p.Asp669PhefsTer', genotypes[0].attribute_map['proteinimpact']
    nobrackets_record = build_raw_record('pseudo_id1' => 'bob')
    nobrackets_record.raw_fields['genotype'] = 'BRCA2 c.2836_2837delGA; p.His669Phefs*12'
    @logger.expects(:debug).with('Found dna mutation in ["BRCA2"] GENE(s) in position [["c.2836_2837delGA"]] with impact [["His669Phefs*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: BRCA2, c.2836_2837delGA, His669Phefs*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA1", "TP53"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, nobrackets_record)
    assert_equal 'p.His669PhefsTer', genotypes[0].attribute_map['proteinimpact']
  end

  test 'process record with cdna mutation' do
    genemutation_record = build_raw_record('pseudo_id1' => 'bob')
    genemutation_record.raw_fields['genotype'] = 'BRCA2 c.2836_2837delGA; p.Asp946Phefs*12'
    @logger.expects(:debug).with('Found dna mutation in ["BRCA2"] GENE(s) in position [["c.2836_2837delGA"]] with impact [["Asp946Phefs*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: BRCA2, c.2836_2837delGA, Asp946Phefs*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA1", "TP53"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, genemutation_record)
    assert_equal 3, genotypes.size
  end

  test 'process record with chromosomal aberration' do
    chromosomemutation_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomemutation_record.raw_fields['genotype'] = 'BRCA1 exon 1-11 deletio'
    @logger.expects(:debug).with('Found CHROMOSOME VARIANT del in BRCA1 GENE at position 1-11')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA2", "TP53"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    genotypes = @handler.extract_variants_from_record(@genotype, chromosomemutation_record)
    assert_equal 3, genotypes.size
  end

  test 'process record with mixed cdna mutation and chromosomal aberration' do
    chromosomecdnamutation_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomecdnamutation_record.raw_fields['genotype'] = 'BRCA2 exon 1-6 deletion plus TP53 c.1847C>G p.Pro616Arg'
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: ["BRCA1"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for BRCA2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for TP53')
    genotypes = @handler.extract_variants_from_record(@genotype, chromosomecdnamutation_record)
    assert_equal 3, genotypes.size
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'Provider Code',
      collecteddate: '2016-03-22T00:00:00.000+00:00',
      receiveddate: '2016-03-23T00:00:00.000+00:00',
      authoriseddate: '2016-07-13T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      specimentype: '5',
      genotype: 'No mutation detected',
      variantpathclass: 'Normal/Wild type',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { genotype: 'No mutation detected',
      variantpathclass: 'Normal/Wild type',
      'test type 1' => 'Next Gen Sequencing',
      'test type 2' => '',
      sex: 'F',
      'clinician desc' => 'Brca Registry',
      consultantcode: 'Consultant Code',
      'specialty desc' => 'UNKNOWN',
      providercode: 'Watford Road',
      'source desc' => 'Source description',
      'source ccg desc' => 'Source Description',
      servicereportidentifier: 'Service Report Identifier',
      specimentype: 'Blood',
      collecteddate: '2016-03-22 00:00:00',
      receiveddate: '2016-03-23 00:00:00',
      authoriseddate: '2016-07-13 00:00:00',
      'all clinical comments (semi colon separated).all clinical comment text' => 'Trusight Cancer panel;Li Fraumeni Syndrome' }.to_json
  end
end
