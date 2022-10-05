require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class GenotypeMmrTest < ActiveSupport::TestCase
  def setup
    @genotype = Import::Colorectal::Core::Genocolorectal.new(build_raw_record('pseudo_id1' => 'bob'))
    @logger   = Import::Log.get_logger
  end

  test 'add_gene_colorectal' do
    string_colorectal_input = @genotype.raw_record.raw_fields['test']
    assert string_colorectal_input.is_a? String
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @genotype.add_gene_colorectal(string_colorectal_input)
    assert_equal 2808, @genotype.attribute_map['gene']

    @logger.expects(:debug).with('SUCCESSFUL gene parse for 577')
    @genotype.add_gene_colorectal(577)
    assert_equal 577, @genotype.attribute_map['gene']

    @logger.expects(:error).with('Invalid gene reference given to addGene; given: 999')
    @genotype.add_gene_colorectal(999)
  end

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_to_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_clinical_to_json
    }

    Import::Germline::RawRecord.new(default_options.merge!(options))
  end

  def clinical_to_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2000-10-16T00:00:00.000+01:00',
      authoriseddate: '2013-02-15T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2000-10-16T00:00:00.000+01:00',
      specimentype: '5',
      requesteddate: '2012-12-07T00:00:00.000+00:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_to_json
    { sex: 'Female',
      providercode: 'Provider Address',
      consultantname: 'Professor Some Body',
      servicereportidentifier: 'Service Report Identifier',
      'service level' => 'NHS',
      moleculartestingtype: 'Breast cancer full screen',
      requesteddate: '2012-12-07 00:00:00',
      receiveddate: '2000-10-16 00:00:00',
      authoriseddate: '2013-02-15 16:36:01',
      specimentype: 'Blood -LiHep',
      status: 'Variant',
      genotype: 'c.670+16G>A',
      test: 'MSH6' }.to_json
  end
end
