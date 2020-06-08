require 'test_helper'

class GrantMatrixTest < ActiveSupport::TestCase
  test 'node category params correctly cleaned' do
    test_params = {
      1 => '',
      2 => '',
      3 => '',
      4 => '1',
      5 => '',
      6 => '1'
    }

    test_params.stringify_keys!

    matrix = NodeCategoryMatrix.new({})
    matrix.send(:clean_up!, test_params)

    assert test_params.is_a? Hash
    assert_equal 6, test_params.length
    assert_equal test_params.values, [false, false, false, true, false, true]
  end
end
