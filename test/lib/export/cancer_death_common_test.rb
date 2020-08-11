require 'test_helper'

class CancerDeathCommonTest < ActiveSupport::TestCase
  test 'match CARA ICD codes' do
    should_match = %w[D821 Q012 Q262 Q605]
    should_match.each do |icd|
      assert_match Export::CancerDeathCommon::CARA_PATTERN, icd
    end
  end

  test 'reject non-CARA ICD codes' do
    should_reject = %w[A020 D823 P524 Q250 Q038 Q039 Q336 Q658 Q673] + ['']
    should_reject.each do |icd|
      assert_no_match Export::CancerDeathCommon::CARA_PATTERN, icd
    end
  end
end
