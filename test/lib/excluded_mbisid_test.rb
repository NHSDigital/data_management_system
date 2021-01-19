require 'test_helper'

class ExcludedMbisidTest < ActiveSupport::TestCase
  test 'dummy mbisid should be excluded' do
    assert ExcludedMbisid.excluded_mbisid?(ExcludedMbisid::DUMMY_MBISID)
  end
end
