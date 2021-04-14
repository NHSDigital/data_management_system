require 'test_helper'

class GenotypeBrcaTest < ActiveSupport::TestCase
  def setup
    @genotype = Import::Brca::Core::GenotypeBrca.new(build_raw_record('pseudo_id1' => 'bob'))
    @logger   = Import::Log.get_logger
  end

  test 'add_gene' do
    string_brca_imput = @genotype.raw_record.raw_fields['test']
    assert string_brca_imput.is_a? String
    # assert_equal true, @genotype.add_gene(string_brca_imput)

    @genotype.add_gene(7)
    assert_equal 7, @genotype.attribute_map['gene']
    @genotype.add_gene(8)
    assert_equal 8, @genotype.attribute_map['gene']
    @genotype.add_gene(1)
    assert_equal 7, @genotype.attribute_map['gene']
    @genotype.add_gene(2)
    assert_equal 8, @genotype.attribute_map['gene']

    @logger.expects(:error).with('Bad input type given for BRCA extraction: ')
    @genotype.add_gene(nil)

    @logger.expects(:error).with('Bad input type given for BRCA extraction: 99.9')
    @genotype.add_gene(99.9.to_f)
  end

  # test 'gene_integer_input' do
  #   assert_equal 7, @genotype.gene_integer_input(1)
  #   assert_equal 8, @genotype.gene_integer_input(2)
  #   assert_equal 7, @genotype.gene_integer_input(7)
  #   assert_equal 8, @genotype.gene_integer_input(8)
  #
  #   @logger.expects(:error).with('Invalid gene reference given to addGene; needs 1 or 2, given: 99')
  #   @genotype.gene_integer_input(99)
  # end

  test 'other_gene' do
    genotype = Import::Brca::Core::GenotypeBrca.new(build_raw_record('pseudo_id1' => 'bob'))
    genotype.add_gene(7)
    assert_equal 8, genotype.other_gene
    genotype.attribute_map['gene'] = 99
    @logger.expects(:warn).with('Something very wrong, trying to get gene opposite of: 99')
    genotype.other_gene
  end

  # test 'gene_regex_input' do
  #   brca_imput = @genotype.raw_record.raw_fields['test']
  #   assert_equal 7, @genotype.gene_regex_input(brca_imput)
  #
  #   @logger.expects(:debug).with('Bad input string given for brca1/2 extraction: Cabbage')
  #   @genotype.gene_regex_input('Cabbage')
  # end

  # test 'gene_string_input' do
  #   brca_imput = @genotype.raw_record.raw_fields['test']
  #   assert_equal 7, @genotype.gene_string_input(brca_imput)
  #
  #   expected = 'Bad input string (too many genes) given for brca1/2 extraction: BRCA1 and BRCA2'
  #   @logger.expects(:debug).with(expected)
  #   @genotype.gene_string_input('BRCA1 and BRCA2')
  #
  #   @logger.expects(:debug).with('Bad input string (no detected genes) given for brca1/2 extraction: Cabbage')
  #   @genotype.gene_string_input('Cabbage')
  #
  #   @logger.expects(:debug).with('WARNING: string provided for gene extraction contains aslash, possible multi-gene error: BRCA1/')
  #   @genotype.gene_string_input('BRCA1/')
  # end

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_to_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' =>  rawtext_clinical_to_json
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end
  
  def clinical_to_json
    {sex: '2',
     consultantcode: 'C2345678',
     providercode: 'RHM12',
     receiveddate: '2000-10-16T00:00:00.000+01:00',
     authoriseddate: '2013-02-15T00:00:00.000+00:00',
     servicereportidentifier: 'W0001234',
     sortdate: '2000-10-16T00:00:00.000+01:00',
     specimentype: '5',
     requesteddate: '2012-12-07T00:00:00.000+00:00',
     age: 37}.to_json
   end
   
   def rawtext_clinical_to_json
   {sex: 'Female',
    providercode: 'Princess Anne Hospital',
    consultantname: 'Professor Some Body',
    servicereportidentifier: 'W0001234',
    'service level' => 'NHS',
    moleculartestingtype: 'Breast cancer full screen',
    requesteddate: '2012-12-07 00:00:00',
    receiveddate: '2000-10-16 00:00:00',
    authoriseddate: '2013-02-15 16:36:01',
    specimentype: 'Blood -LiHep',
    status: 'Variant',
    genotype: 'c.670+16Gu003eA',
    test: 'BRCA1 mutation analysis'}.to_json
  end
end
