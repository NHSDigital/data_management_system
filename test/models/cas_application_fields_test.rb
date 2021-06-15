require 'test_helper'
class CasApplicationFieldsTest < ActiveSupport::TestCase
  test 'handling `declaration` attribute' do
    choices = %w[1Yes 2No 4Yes]
    ca = CasApplicationFields.new(declaration: choices)
    assert_equal '1Yes,2No,4Yes', ca.declaration
    expected_hash = { '1' => 'Yes', '2' => 'No', '4' => 'Yes' }
    assert_equal expected_hash, ca.declaration_choices
  end

  test 'must have all declarations set to yes' do
    ca = CasApplicationFields.new(declaration: [])

    ca.valid?
    assert ca.errors.messages[:declaration].include? 'All declarations must be yes before an ' \
                                                     'application can be submitted'

    ca = CasApplicationFields.new(declaration: %w[1No 2No 3No 4No])
    ca.valid?
    assert ca.errors.messages[:declaration].include? 'All declarations must be yes before an ' \
                                                     'application can be submitted'

    ca = CasApplicationFields.new(declaration: %w[1Yes 2No 3No 4No])
    ca.valid?
    assert ca.errors.messages[:declaration].include? 'All declarations must be yes before an ' \
                                                     'application can be submitted'

    ca = CasApplicationFields.new(declaration: %w[1Yes 2Yes 4Yes])
    ca.valid?
    assert ca.errors.messages[:declaration].include? 'All declarations must be yes before an ' \
                                                     'application can be submitted'

    ca = CasApplicationFields.new(declaration: %w[1Yes 2Yes 3Yes 4Yes])
    ca.valid?
    refute ca.errors.messages[:declaration].include? 'All declarations must be yes before an ' \
                                                     'application can be submitted'
  end
end
