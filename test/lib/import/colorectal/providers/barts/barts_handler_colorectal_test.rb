require 'test_helper'

class BartsHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record = build_raw_record('pseudo_id1' => 'bob')
    @genocolorectal = Import::Colorectal::Core::Genocolorectal.new(@record)
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Barts::BartsHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'process_genetictestcope' do
    targ_record = build_raw_record('pseudo_id1' => 'bob')
    @handler.add_genetictestscope(@genocolorectal, targ_record)
    assert_equal 'Targeted Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']

    fs_record = build_raw_record('pseudo_id1' => 'bob')
    fs_record.raw_fields['testscope'] = 'Diagnostic'
    @handler.add_genetictestscope(@genocolorectal, fs_record)
    assert_equal 'Full screen Colorectal Lynch or MMR', @genocolorectal.attribute_map['genetictestscope']
  end

  private

  def clinical_json
    { sex: '2',
      codingdnasequencechange: 'c.123A>T',
      proteinimpact: 'p.126MT',
      variantpathclass: 1,
      gene: 2808,
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { 'lab' => 'Brimingham',
      'sex' => 2,
      'testscope' => 'Predictive',
      'authoriseddate' => '12/04/2018 00:00',
      'gene' => 'MLH1',
      'variantpathclass' => 'Class 1',
      'consultantname' => 'Dr. Smith',
      'codingdnasequencechange' => 'c.123A>T',
      'proteinimpact' => 'p.126MT' }.to_json
  end
end
