require 'test_helper'
# require 'import/utility/pseudonymised_file_wrapper'

class BrcaTest < ActiveSupport::TestCase
  test 'intialize' do
    file = Rails.root.join('test/fixtures/files/DUMMY_PSEUDO.pseudo')
    fw   = Import::Utility::PseudonymisedFileWrapper.new(file)

    # FIXME: Commit a dummy file suitable for testing and then remove this guard.
    skip unless File.exist?(file)

    fw.process

    assert fw.process[0][:map1].include? 'age'
  end
end
