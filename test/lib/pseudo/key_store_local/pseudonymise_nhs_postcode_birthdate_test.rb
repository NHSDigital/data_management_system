require 'test_helper'

module Pseudo
  class KeyStoreLocal
    # Test support for partial / incomplete demographics in PseudonymiseNhsPostcodeBirthdateTest
    class PseudonymiseNhsPostcodeBirthdateTest < ActiveSupport::TestCase
      setup do
        @nhsnumber = '9999999468'
        @surname = 'EDITTESTPATIENT'
        @forenames = 'ONE'
        @birthdate = '1925-01-27'
        @postcode = 'B6 5RQ'
        @blankfield = ' ' # Test a demographic field that has value ' ', i.e. blank but not empty.
        @key_names = %w[unittest_pseudo_molecular]
        ENV['MBIS_KEK'] = 'test'
        @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
      end

      test 'pseudo_ids' do
        # Returns an array, where each element contains [key, pseudo_id1, pseudo_id2]
        pseudo_ids_list1 = @keystore.pseudo_ids(@key_names, @nhsnumber, @postcode, @birthdate, :match)
        assert_equal([%w[unittest_pseudo_molecular
                         2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9
                         dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3]],
                     pseudo_ids_list1)
        pseudo_ids_list2 = @keystore.pseudo_ids(@key_names, @nhsnumber, '', '', :match)
        assert_equal([%w[unittest_pseudo_molecular
                         2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9
                         de0128b7674468e103a846bd31dcf4ba0cc0bd099aaac8f56f2fba1e8439d90c]],
                     pseudo_ids_list2)
        pseudo_ids_list3 = @keystore.pseudo_ids(@key_names, '', @postcode, @birthdate, :match)
        assert_equal([%w[unittest_pseudo_molecular
                         6e6819ef00c8c4abd3b50da66b85cca1032777f1ea7cb28fb3c50d647733c191
                         dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3]],
                     pseudo_ids_list3)
        pseudo_ids_list4 = @keystore.pseudo_ids(@key_names, '', '', '', :match)
        assert_equal([%w[unittest_pseudo_molecular
                         6e6819ef00c8c4abd3b50da66b85cca1032777f1ea7cb28fb3c50d647733c191
                         de0128b7674468e103a846bd31dcf4ba0cc0bd099aaac8f56f2fba1e8439d90c]],
                     pseudo_ids_list4)
      end

      test 'encrypt and decrypt demographics' do
        dump_key_names = []
        # dump_key_names = %w[unittest_pseudo_molecular]
        skip_keys = []
        @key_names.each do |key_name|
          next if skip_keys.include?(key_name)

          demog_hash = { 'nhsnumber' => @nhsnumber, 'postcode' => @postcode, 'birthdate' => @birthdate, 'surname' => @surname, 'forenames' => @forenames, 'blankfield' => @blankfield }
          demog_json = demog_hash.to_json
          check_encryption(
            @keystore, key_name, :demographics, demog_json, @nhsnumber, @postcode, @birthdate,
            dump_output: dump_key_names.include?(key_name),
            context: 'Full demographics (should decrypt with both pseudo_id1 + pseudo_id2)'
          )
          check_encryption(
            @keystore, key_name, :demographics, demog_json, @nhsnumber, '', '',
            dump_output: dump_key_names.include?(key_name),
            context: 'Only nhsnumber (should decrypt with only pseudo_id1, not pseudo_id2)'
          )
          check_encryption(
            @keystore, key_name, :demographics, demog_json, @nhsnumber, '', @birthdate,
            dump_output: dump_key_names.include?(key_name),
            context: 'Only nhsnumber + birthdate (should decrypt with only pseudo_id1, ' \
                     'not pseudo_id2)'
          )
          check_encryption(
            @keystore, key_name, :demographics, demog_json, '', @postcode, @birthdate,
            dump_output: dump_key_names.include?(key_name),
            context: 'Only postcode + birthdate (should decrypt with only pseudo_id2, not ' \
                     'pseudo_id1)'
          )
          assert_raises(OpenSSL::Cipher::CipherError, ArgumentError,
                        'Expect an exception when trying to decrypt with insufficient ' \
                        'demographics - only postcode') do
            check_encryption(
              @keystore, key_name, :demographics, demog_json, '', @postcode, '',
              dump_output: dump_key_names.include?(key_name),
              context: 'No nhsnumber or birthdate (should not decrypt with pseudo_id1 or ' \
                       'pseudo_id2)'
            )
          end
          assert_raises(OpenSSL::Cipher::CipherError, ArgumentError,
                        'Expect an exception when trying to decrypt with insufficient ' \
                        'demographics (only postcode)') do
            check_encryption(
              @keystore, key_name, :demographics, demog_json, '', '', '',
              dump_output: dump_key_names.include?(key_name),
              context: 'No nhsnumber, postcode or birthdate (should not decrypt with pseudo_id1 ' \
                       'or ppseudo_id2)'
            )
          end
        end

        # TODO: Test failed decryption with incorrect demographics
        skip 'TODO: Support extra key types in skip_keys' if skip_keys.present?
      end

      test 'encrypt and decrypt demographics with different demographics' do
        @key_names.each do |key_name|
          demog_hash = { 'nhsnumber' => @nhsnumber, 'postcode' => @postcode, 'birthdate' => @birthdate, 'surname' => @surname, 'forenames' => @forenames, 'blankfield' => @blankfield }
          demog_json = demog_hash.to_json
          pseudo_id1, pseudo_id2, decrypt_key, rawdata = @keystore.encrypt_record(key_name, :demographics, demog_json, @nhsnumber, @postcode, @birthdate, :create)
          begin
            decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, @nhsnumber, '', '', :match)
          rescue OpenSSL::Cipher::CipherError
            flunk('Record pseudonymised with nhsnumber, postcode and birthdate ' \
                  'should unlock with just nhsnumber')
          end
          assert_equal(demog_json, decrypted_json)
          begin
            decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, '', @postcode, @birthdate, :match)
          rescue OpenSSL::Cipher::CipherError
            flunk('Record pseudonymised with nhsnumber, postcode and birthdate should ' \
                  'unlock with just postcode and birthdate')
          end
          assert_equal(demog_json, decrypted_json)
        end
      end

      # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
      test 'decrypt existing data' do
        # To produce sample data, set dump_key_names in test 'encrypt and decrypt demographics' above.
        [
          ['unittest_pseudo_molecular', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE","blankfield":" "}', '9999999468', '1925-01-27', 'B6 5RQ',
           # '2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9', # pseudo_id1
           # 'dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3', # pseudo_id2
           # "\xE3\xABj\x9C\xD0I\xB2\xB7&\x97\xB8\xB7\xE7\xEF{\xC6~\xE1\xDC\xB9\x80\x1F\xE4\xA5)\xF9\xEA\xE5\xA0\xDA\n\xDFn^\x89n6d\xAC\x15\xCA\x9Ed\x1C\x7F\t\xD2%\xE5\xC4?\xB0:\x96\xF0G\x97\r\xDD\xFE\xC7o\x02\x8A\xCD5\xEB\xA0\b\xF5\xDBJP\x87\xCE\x94NT\xE2\xF6hj\xE6\xC0v\t\x81cCP\xA4\xDE1\xCAv\xB3\\Z\xB6\xA8\x01*\xCFQFY\x92y\xAC\xDE\xC4\xB20\x0F\xD6\xF1\xFA^\xDD\xA9\e\x8B\xF0\xA83\x83\b\xAE)F$V[\x82!IX\x9F\t\xF6\xB1\xCD\xC5\\W\x01\xEA&j\x98^\xAC\xE4\x06\x7FAk\xFB\x9DH\xAE9*@\xD0\xC8\xC1#}+\xF8\xBD\xD5\xE0\x8D\x14M|U\x1A\x11a\xE8\xC2\xAB\x8A\x89\x1F\xB1\xE6i\x01\x1A\x11\x88\x7F\e!}\xD6A\f\xF7q\xEC\x8A\xB6\x1E>vv<\x16\x8C\xA5\xF8\\\xA9e\xA7\x87)\x84v@8\x0F\x12\xE2\xBA\x9D\xAB_\xCCR\xB1\xD8\xE1\x9C\"\x9E\xEA\xE4\xF8.\xAC\xC9\xFC\xDC\xF5\f\x83\xF7\x99%\xB3\x93\xF6\x11@Ly\xF3\xBE\x1D\x9C\x96\xEE\xBF\xFE\x0E\xF5\xC0\x924\\_\xE4}\xEE-\x1A\xF0t\x87\x12o8\xC5k\xE9\x06\x8E\xE4D'\x86\xF3\xD5(u\xA0\x11\xF8\x1F8\x1C\xAE\xF8{\xF4\xAD\xEA\xD8n\xF1\xFE\xF6(\xB5", # decrypt_key, before base64 encoding, 320 characters
           Base64.strict_decode64('46tqnNBJsrcml7i35+97xn7h3LmAH+SlKfnq5aDaCt9uXoluNmSsFcqeZBx/CdIl5cQ/sDqW8EeXDd3+x28Cis0166AI9dtKUIfOlE5U4vZoaubAdgmBY0NQpN4xynazXFq2qAEqz1FGWZJ5rN7EsjAP1vH6Xt2pG4vwqDODCK4pRiRWW4IhSVifCfaxzcVcVwHqJmqYXqzkBn9Ba/udSK45KkDQyMEjfSv4vdXgjRRNfFUaEWHowquKiR+x5mkBGhGIfxshfdZBDPdx7Iq2Hj52djwWjKX4XKllp4cphHZAOA8S4rqdq1/MUrHY4Zwinurk+C6syfzc9QyD95kls5P2EUBMefO+HZyW7r/+DvXAkjRcX+R97i0a8HSHEm84xWvpBo7kRCeG89UodaAR+B84HK74e/St6thu8f72KLU='), # decrypt_key
           # "$t\xDD\xDA\t\xDA}*evV2;\x8D\xCC\xDC*\xA3\f\xF3:s\x98{p\xA4~\xAF\x9B\x80\xED\"\x9Fc+\x17\x03\xA3\xA1\x88%X\x89pS\x04\x0E\x18&/\xF5\xADy\xF9\xAE\xAD\"O.\xB5\xE9M\x01\x96\x88\xF5\xFC\xF6\xF8\xEBb\xFE\xC8|\xA2\xED\xC6C\x02\xAC[_\v\xFE\xE5&\x1D\x16+\x1F^5MM\xB9\xEA\xDD#`\xCA\x16\xD8\xEF\x1C^\x1F\x904~\xF0X\xC4\xB6\x9B\e\xA1\xB7\x1A\xB2\xB8$\xCB,,\x03\xDB\xF6B\xAA\xC9\x9C?\x13X\xE1Ra\xD7\x1A\xAB\x80\xC5\xBE\xCB", # rawdata, before base64 encoding, 144 characters
           Base64.strict_decode64('JHTd2gnafSpldlYyO43M3CqjDPM6c5h7cKR+r5uA7SKfYysXA6OhiCVYiXBTBA4YJi/1rXn5rq0iTy616U0Bloj1/Pb462L+yHyi7cZDAqxbXwv+5SYdFisfXjVNTbnq3SNgyhbY7xxeH5A0fvBYxLabG6G3GrK4JMssLAPb9kKqyZw/E1jhUmHXGquAxb7L')], # rawdata
          ['unittest_pseudo_molecular', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE","blankfield":" "}', '9999999468', '', '',
           # '2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9', # pseudo_id1
           # 'de0128b7674468e103a846bd31dcf4ba0cc0bd099aaac8f56f2fba1e8439d90c', # pseudo_id2
           # "\\\xD4\x7F\xA0\v\xCFk\xFC\n4\xCERp\x9B\x8F\x9D@)8\xC1\x8A\xCB\xF6\x9A<\xA4\x00\xCE{\xBEF\xFD\x8A[\xABV0\x9E\n\xEA\xBE\xB8\xBF\xEF\xFBA:\x12Y\x10\x8AUd~S\xBC\x00\x9F\xEF\x8A\xB0\e\xF9\xB4\xB0\xA7*\b\x9A\a*\n\x81I\xC4h\x9E\xC4\v7\xF6$OIM\xB6\xC5\n\xA1\xEA\xFC\xEC2\xC7Y\xC0\xF3c\xA0\xFE\xDB\xE0~\xD8\xCA\xD2\x93\xF4\xBF\xFF\x1Dl\xE1<\x9C(\xC2\x1E\xF3(\xA0Dr\xB9~M>h\xF1\xE3\x8E\xC0)\x96\xF2\xDFre\xACW5\x8CU@U\xA1]\x95/\"\x93VT\xDA\x16\xC8\xC0\x86\xDDd", # decrypt_key, before base64 encoding, 160 characters
           Base64.strict_decode64('XNR/oAvPa/wKNM5ScJuPnUApOMGKy/aaPKQAznu+Rv2KW6tWMJ4K6r64v+/7QToSWRCKVWR+U7wAn++KsBv5tLCnKgiaByoKgUnEaJ7ECzf2JE9JTbbFCqHq/Owyx1nA82Og/tvgftjK0pP0v/8dbOE8nCjCHvMooERyuX5NPmjx447AKZby33JlrFc1jFVAVaFdlS8ik1ZU2hbIwIbdZA=='), # decrypt_key
           # "v\x06/W\x98\xAAiW\xF3/\xD2\x89\xBD\x1C\x19\b\x19N\xCD{\xB0\x12c\xA3\\b\xAC#j^*\x1E\xAE\x9C\xEA\xED\xB8~\xFB\x01\xF7\xAA\xA8^Y\xF3\xEF\xBE\xB9\x7F\xA07\xB6~\xC8\xF7B\xB9y\xDFY\x82S\xEA\xAFg\xAFIN\x03+tv\x99\xB6-i\xFC\xB9\x15\xAA\x99\xCE\x9D\x0F\xF4\xE2(\xCDs\xD7\x1D\x85\xFBd\xF5\xDB@,\x98\x9B\xC9&\x99\x90\bX\xC4\x8F\x15\x96\x02'9\x89=6\x98\x91\xDF.\xA7\x89\v\x10\xF9\x99w\x16(5/k\xE2`2\xBA\xC3F3\xF9\xCC8\xE1", # rawdata, before base64 encoding, 144 characters
           Base64.strict_decode64('dgYvV5iqaVfzL9KJvRwZCBlOzXuwEmOjXGKsI2peKh6unOrtuH77AfeqqF5Z8+++uX+gN7Z+yPdCuXnfWYJT6q9nr0lOAyt0dpm2LWn8uRWqmc6dD/TiKM1z1x2F+2T120AsmJvJJpmQCFjEjxWWAic5iT02mJHfLqeJCxD5mXcWKDUva+JgMrrDRjP5zDjh')], # rawdata
          ['unittest_pseudo_molecular', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE","blankfield":" "}', '9999999468', '1925-01-27', '',
           # '2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9', # pseudo_id1
           # '92f4df3623ed55c7e5dc3f682939c873cf04714715e5d7a7c651cef26c714a29', # pseudo_id2
           # ".u\xF5$\xA8\x96lm\x84\x86\xAB\xFE\xAC\xF6b\x06M^\xCD\x8D\x0E\xD5\x9F\x97\xC3\xA7\xE4\x1CY'&ax\xF4B\xEB\r\x9C\x15\xE4\xFA\xBF\x1C\x9F\xF1\xB3Bu\xD4\xB6\ek\xFD\x9C\xA3\xC6\xCEnrY\xE4\xC9\fB\xB2\xE4\xFB\x0F\xE1\xAB\xB3\xFC\xC1J=q\x91\x8C\x82\xA5\xA0~J\xE9\x84qY\x9B\xC0\xA9D\xEC\xF5\x87A\x1F\xB7?\x83(W\x96\x1F\xD7\xBA\xAA\x88\x01\xF8\x98U\xCA\xB7Kb\x9A\xB1\xC51\x8D\x8E\xE8\xC9\xD7\xF7I\x9BC\xAC\x80\x05Vi\xAF\\\xE7\x8C\xCA\x10\xE14u9X\xB7\x83P\xBC\r7\x04\v\xE7\xB6tWh/\xA0\xC3", # decrypt_key, before base64 encoding, 160 characters
           Base64.strict_decode64('LnX1JKiWbG2Ehqv+rPZiBk1ezY0O1Z+Xw6fkHFknJmF49ELrDZwV5Pq/HJ/xs0J11LYba/2co8bObnJZ5MkMQrLk+w/hq7P8wUo9cZGMgqWgfkrphHFZm8CpROz1h0Eftz+DKFeWH9e6qogB+JhVyrdLYpqxxTGNjujJ1/dJm0OsgAVWaa9c54zKEOE0dTlYt4NQvA03BAvntnRXaC+gww=='), # decrypt_key
           # "\x8En|>\xD7f\xBC\xE2\x83<\xDF\f\x86.p\xD2,\x80\xCE\xD2\x14\x98\x13W\xCD\xEFJ\x8FSV\x80BiC&\xD1+\xB6A\xDAWdo\xB9\x16\n\xF8ui8\x7F\xB0\vv\xE1\xD7\xCF\\^^OU\xC9\x1FP'\xFAU4x\x0E\x9A\x91\xED\xF9\xC4S\xBC\xCA!\xB6\xC2\xF38t\xD5\xEB\xEB\xA6H\x8Eh\x00\xECO\x98jnY{_aE9\xEF\xC0\x12\xA6t\ty\x86\x80(\xE9\x97$\x8Aj\xA8C=\x18\xB9=\x80Z\xFCrcj-\xE9\xD4S\xBBw\xC5\xC8\\\xD1\x1E\xB4\xA1", # rawdata, before base64 encoding, 144 characters
           Base64.strict_decode64('jm58PtdmvOKDPN8Mhi5w0iyAztIUmBNXze9Kj1NWgEJpQybRK7ZB2ldkb7kWCvh1aTh/sAt24dfPXF5eT1XJH1An+lU0eA6ake35xFO8yiG2wvM4dNXr66ZIjmgA7E+Yam5Ze19hRTnvwBKmdAl5hoAo6ZckimqoQz0YuT2AWvxyY2ot6dRTu3fFyFzRHrSh')], # rawdata
          ['unittest_pseudo_molecular', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE","blankfield":" "}', '', '1925-01-27', 'B6 5RQ',
           # '6e6819ef00c8c4abd3b50da66b85cca1032777f1ea7cb28fb3c50d647733c191', # pseudo_id1
           # 'dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3', # pseudo_id2
           # "u\xC5\xD1\x85\x15['(I\xB5\xE1\xB1\x14\xD0\xFCPW\xAAm\xF5J\x8F\xF9\xB3\xB2*~\x92EA6\xD1XX\xAF\x82\x89 \xF3JV]\x87Yw\x98\xA9q\v'1\xC6\xF3\xF0\x9CNJ\xE2\x90\x10\x17\xB9\xD2ho\xB8\xC6\xB9\xF5\xAE/X\xDD\x00ma\xCC\xC94\xD1TZ\xF1\xAC\\\xA6\xED\x04\x11\xE8m\x90Y\xE2\f\xA6\xD6J\xC7\xAC\xEE~\b\x86\xCD4\x93\xC0 Ad\xE2p\x17v&\xCF\x16R\xEB\xED\t\xE9\x7Fx/\xC8k\e\r;x\xE0d\x012c,\x91\xE1\xEDR\x8Ba!G`W\xB7!\x85\x85\x1D\xFByY\xFC\x98\x7F\x03", # decrypt_key, before base64 encoding, 160 characters
           Base64.strict_decode64('dcXRhRVbJyhJteGxFND8UFeqbfVKj/mzsip+kkVBNtFYWK+CiSDzSlZdh1l3mKlxCycxxvPwnE5K4pAQF7nSaG+4xrn1ri9Y3QBtYczJNNFUWvGsXKbtBBHobZBZ4gym1krHrO5+CIbNNJPAIEFk4nAXdibPFlLr7Qnpf3gvyGsbDTt44GQBMmMskeHtUothIUdgV7chhYUd+3lZ/Jh/Aw=='), # decrypt_key
           # "\x849VO\x9B\xF3\xA6\x17\xBDTP\xBA\x00\\\x81\x05\xBB\x82\xE9}\x1A\t\x90\xAB\x0F\xDEg\xA2\xC7b\xE2 \xCD\x11\xFC\xE4\x0E\xE4\xA4\xF0Y/\x90b\xCC\x86Y\xCF\x98\xC0\x8A\xBE#\x9B\x81\x7F_\xEB q\x15[sT\xB7\xC2\e\xC1\x90\xC7dY|\xD7 ^0\xAEf\r\xDF\xCA-\x89\x15\r%X\xD3\x82\xDBR\x04\x84+\xE7D4\r\x1E#\x03\x12R\xD1\xCE\xEEB\xC6>%|4\x86\xC18\xE2\xB5:\x853\x89\xE3\xF6\x16\xD11\xF9q\bwg=x\x95\xE4\x0F\xFB\x83\xFB\xF5L\xAD\x18", # rawdata, before base64 encoding, 144 characters
           Base64.strict_decode64('hDlWT5vzphe9VFC6AFyBBbuC6X0aCZCrD95nosdi4iDNEfzkDuSk8FkvkGLMhlnPmMCKviObgX9f6yBxFVtzVLfCG8GQx2RZfNcgXjCuZg3fyi2JFQ0lWNOC21IEhCvnRDQNHiMDElLRzu5Cxj4lfDSGwTjitTqFM4nj9hbRMflxCHdnPXiV5A/7g/v1TK0Y')] # rawdata
        ].each do |key_name, demographics, nhsnumber2, birthdate2, postcode2, decrypt_key, rawdata|
          decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, nhsnumber2, postcode2, birthdate2, :match)
          assert_equal(demographics, decrypted_json)
        end
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def check_encryption(keystore, key_name, data_type, rawvalue,
                           nhsnumber, postcode, birthdate, dump_output: false, context: nil)
        pseudo_id1, pseudo_id2, decrypt_key, rawdata = keystore.encrypt_record(key_name, data_type, rawvalue, nhsnumber, postcode, birthdate, :create)
        decrypted_json = keystore.decrypt_record(key_name, data_type, decrypt_key, rawdata, nhsnumber, postcode, birthdate, :match)
        assert_equal(rawvalue, decrypted_json, context)
        return unless dump_output

        puts <<~RUBY
          # Sample data for test 'decrypt existing data':
          ['#{key_name}', '#{rawvalue}', '#{nhsnumber}', '#{birthdate}', '#{postcode}',
           # '#{pseudo_id1}', # pseudo_id1
           # '#{pseudo_id2}', # pseudo_id2
           # #{decrypt_key.inspect}, # decrypt_key, before base64 encoding, #{decrypt_key.size} characters
           Base64.strict_decode64('#{Base64.strict_encode64(decrypt_key)}'), # decrypt_key
           # #{rawdata.inspect}, # rawdata, before base64 encoding, #{rawdata.size} characters
           Base64.strict_decode64('#{Base64.strict_encode64(rawdata)}')] # rawdata
        RUBY
      end
    end
  end
end
