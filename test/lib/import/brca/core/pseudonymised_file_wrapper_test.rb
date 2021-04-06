require 'test_helper'
#require 'import/central_logger'

class PseudonymisedFileWrapperTest < ActiveSupport::TestCase
  test 'intialize' do
    # file    = Rails.root.join('test', 'fixtures', 'files', 'DUMMY_PSEUDO.pseudo')
    @logger = Import::Log.get_auxiliary_logger
    assert instance_variable_defined?("@logger")
  end
end
