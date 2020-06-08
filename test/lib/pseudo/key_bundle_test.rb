require 'test_helper'

module Pseudo
  class KeyBundleTest < ActionDispatch::IntegrationTest
    test 'retrieve keys' do
      ENV['MBIS_KEK'] = 'test'
      bundle = KeyBundle.new
      assert(bundle.extract(:unittest_pseudo_prescr))
      assert(bundle.extract(:unittest_encrypt))
      assert_nil(bundle.extract('unittest_pseudo_prescr'))
      assert_nil(bundle.extract(:nonexistent_key))
    end
  end
end
