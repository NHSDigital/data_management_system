require 'test_helper'

class GenotypeTest < ActiveSupport::TestCase
  test 'intialize' do
    genotype = Import::Germline::Genotype.new(build_raw_record('pseudo_id1' => 'bob'))
    assert_equal 'bob', genotype.pseudo_id1
  end

  private

  def build_raw_record(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => {}.to_json,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => {}.to_json
    }

    Import::Germline::RawRecord.new(default_options.merge!(options))
  end
end
