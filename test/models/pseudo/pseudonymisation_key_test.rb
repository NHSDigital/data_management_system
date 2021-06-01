require 'test_helper'

module Pseudo
  # Test Pseudo::PseudonymisationKey model
  class PseudonymisationKeyTest < ActiveSupport::TestCase
    test 'pack_decrypt_key and unpack_decrypt_key' do
      # Illustrative binary keys, all 80 bytes long
      packed_keys = ['0123456789ABCDEFGHIJ' * 4, 'B' * 80, "\x00" * 80, 'D' * 80].
                    collect { |s| s.encode(Encoding::ASCII_8BIT) }
      # Corresponding base-64 encoded keys
      unpacked_keys = ['MDEyMzQ1Njc4OUFCQ0RFRkdISUowMTIzNDU2Nzg5QUJDREVGR0hJSj' \
                       'AxMjM0NTY3ODlBQkNERUZHSElKMDEyMzQ1Njc4OUFCQ0RFRkdISUo=',
                       'QkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQk' \
                       'JCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkI=',
                       'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
                       'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
                       'RERERERERERERERERERERERERERERERERERERERERERERERERERERE' \
                       'REREREREREREREREREREREREREREREREREREREREREREREREREREQ=']

      packed_keys.each.with_index do |key, i|
        assert_equal(key.size, 80)
        assert_equal(unpacked_keys[i], Base64.strict_encode64(key),
                     'packed_keys should match unpacked_keys')
        assert_equal(key, Base64.strict_decode64(unpacked_keys[i]),
                     'unpack_keys should match packed_keys')
      end

      key_combinations = [['', '', 'empty key'],
                          [packed_keys[0], unpacked_keys[0], 'single key 0'],
                          [packed_keys[1], unpacked_keys[1], 'single key 1'],
                          [packed_keys[2], unpacked_keys[2], 'single key 2'],
                          [packed_keys[3], unpacked_keys[3], 'single key 3'],
                          [packed_keys[0..1].join, unpacked_keys[0..1].join(' '), 'two keys'],
                          [packed_keys[2..3].join, unpacked_keys[2..3].join(' '), 'two more keys'],
                          [packed_keys[0..3].join, unpacked_keys[0..3].join(' '), 'four keys']]
      key_combinations.each do |packed_key, unpacked_key, description|
        assert_equal(unpacked_key, PseudonymisationKey.unpack_decrypt_key(packed_key),
                     "unpack_decrypt_key should support #{description}")
        assert_equal(packed_key, PseudonymisationKey.pack_decrypt_key(unpacked_key),
                     "pack_decrypt_key should support #{description}")
      end
    end
  end
end
