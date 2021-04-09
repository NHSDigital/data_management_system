require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class NottinghamHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Nottingham::NottinghamHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
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

  test 'add_test_type' do
    @handler.add_test_type(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['moleculartestingtype']
  end

  test 'extract_teststatus' do
    @handler.extract_teststatus(@genotype, @record)
    assert_equal 2, @genotype.attribute_map['teststatus']
  end

  test 'add_variant' do
    @handler.add_variant(@genotype, @record)
    assert_equal 'c.350C>T', @genotype.attribute_map['codingdnasequencechange']
  end

  test 'add_protein_impact' do
    @handler.add_protein_impact(@genotype, @record)
    assert_equal 'p.Thr117Met', @genotype.attribute_map['proteinimpact']
  end

  test 'process_gene_colorectal' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL COLORECTAL gene parse for: MLH1')
    @handler.process_gene_colorectal(@genotype, @record)
    assert_equal 2744, @genotype.attribute_map['gene']
  end

  test 'add_scope' do
    @handler.add_scope(@genotype, @record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genotype.attribute_map['genetictestscope']
  end

  test 'extract_variantclass_from_genotype' do
    @logger.expects(:debug).with('SUCCESSFUL VARPATHCLASS parse for: 5')
    @handler.extract_variantclass_from_genotype(@genotype, @record)
    assert_equal 5, @genotype.attribute_map['variantpathclass']
    novarpathclass_record = build_raw_record('pseudo_id1' => 'bob')
    novarpathclass_record.raw_fields['teststatus'] = 'Cabbage'
    @logger.expects(:debug).with('FAILED VARPATHCLASS parse for: Cabbage')
    @handler.extract_variantclass_from_genotype(@genotype, novarpathclass_record)
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'C9999998',
      providercode: 'RWEAA',
      receiveddate: '2018-12-11T00:00:00.000+00:00',
      authoriseddate: '2018-12-28T00:00:00.000+00:00',
      sortdate: '2018-12-11T00:00:00.000+00:00',
      genetictestscope: 'Predictive',
      specimentype: '5',
      gene: '2744',
      requesteddate: '2018-12-13T00:00:00.000+00:00',
      age: 44 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'Female',
      providercode: 'Leicester Royal Infirmary',
      consultantname: 'Mx Name De Othername',
      servicereportidentifier: 'N1234567',
      'patient type' => 'NHS',
      disease: 'HNPCC PST',
      moleculartestingtype: 'Predictive',
      gene: 'MLH1',
      genotype: 'c.350C>T p.(Thr117Met)',
      teststatus: '5: clearly pathogenic',
      requesteddate: '2018-12-13 00:00:00',
      receiveddate: '2018-12-11 00:00:00',
      specimentype: 'Whole Blood',
      authoriseddate: '2018-12-28 00:00:00' }.to_json
  end
end
