require 'test_helper'
class CasApplicationFieldsTest < ActiveSupport::TestCase
  test 'handling `declaration` attribute' do
    choices = %w[1Yes 2No 4Yes]
    ca = CasApplicationFields.new(declaration: choices)
    assert_equal '1Yes,2No,4Yes', ca.declaration
    expected_hash = { '1' => 'Yes', '2' => 'No', '4' => 'Yes' }
    assert_equal expected_hash, ca.declaration_choices
  end
end
