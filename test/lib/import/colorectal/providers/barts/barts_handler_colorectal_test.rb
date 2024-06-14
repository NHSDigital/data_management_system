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

  test 'assign_variant_details' do
    fake_record = build_raw_record('pseudo_id1' => 'bob')
    @handler.assign_variant_details(@genocolorectal, fake_record)
    assert_equal 'c.1009C>T', @genocolorectal.attribute_map['codingdnasequencechange']
    assert_equal 'p.Gln337x', @genocolorectal.attribute_map['proteinimpact']
  end

  private

  def clinical_json
    {}.to_json
  end

  def rawtext_clinical_json
    { 'diagnostic lab' => 'RWEAA',
      'authoriseddate' => '12/04/2018 00:00',
      'gene' => 'MLH1',
      'variant' => 'c.1009C>T p.Gln337X',
      'variantpathclass' => '5' }.to_json
  end
end
