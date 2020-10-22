require 'test_helper'
class CasApplicationTest < ActiveSupport::TestCase
  test 'handling `extra_datasets` attribute' do
    choices = %w[1 3 5]
    ca = CasApplication.new(extra_datasets: choices)
    assert_equal choices, ca.extra_datasets
    assert_equal '1,3,5', ca.read_attribute(:extra_datasets)
  end

  test 'handling `declaration` attribute' do
    choises = %w[1Yes 2No 4Yes]
    ca = CasApplication.new(declaration: choises)
    assert_equal '1Yes,2No,4Yes', ca.declaration
    expected_hash = { '1' => 'Yes', '2' => 'No', '4' => 'Yes' }
    assert_equal expected_hash, ca.declaration_choices
  end
end
