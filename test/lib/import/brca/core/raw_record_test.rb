require 'test_helper'

class RawRecordTest < ActiveSupport::TestCase
  test 'raw_all' do
    options = { 'encrypted_rawtext_demog' => 'aaabbcccc', 'rawtext_clinical.to_json' => { 'hello' => 'world' }.to_json }
    raw_record = build_raw_record(options)
    expected_raw_all = { 'hello' => 'world', 'encrypted_rawtext_demog' => 'aaabbcccc', 'encrypted_demog' => '' }
    assert_equal expected_raw_all, raw_record.raw_all
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
