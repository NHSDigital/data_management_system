require 'test_helper'

module Pseudo
  # Test stability of data encryption / decryption with various encryption methods
  class KeyStoreLocalTest < ActiveSupport::TestCase
    setup do
      @nhsnumber = '9999999468'
      @surname = 'EDITTESTPATIENT'
      @forenames = 'ONE'
      @birthdate = '1925-01-27'
      @postcode = 'B6 5RQ'
      @blankfield = ' ' # Test a demographic field that has value ' ', i.e. blank but not empty.
      @key_names = %w[unittest_pseudo_prescr unittest_encrypt unittest_pseudo_molecular]
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
    end

    test 'pseudo_ids' do
      # Returns an array, where each element contains [key, pseudo_id1, pseudo_id2]
      pseudo_ids_list = @keystore.pseudo_ids(@key_names, @nhsnumber, @postcode, @birthdate, :match)
      assert_equal([['unittest_pseudo_prescr',
                     '050d0c4071f4b440c081ca70ad4e319989a03c2f32ea9e7c5719071b564aab0f', nil],
                    %w[unittest_encrypt
                       2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9
                       dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3],
                    # Deliberately re-using salt from unittest_encrypt
                    %w[unittest_pseudo_molecular
                       2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9
                       dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3]],
                   pseudo_ids_list)
    end

    test 'encrypt and decrypt demographics' do
      dump_key_names = []
      # dump_key_names = %w[unittest_pseudo_molecular]
      skip_keys = []
      @key_names.each do |key_name|
        next if skip_keys.include?(key_name)

        demog_hash = { 'nhsnumber' => @nhsnumber, 'postcode' => @postcode, 'birthdate' => @birthdate, 'surname' => @surname, 'forenames' => @forenames, 'blankfield' => @blankfield }
        demog_json = demog_hash.to_json
        pseudo_id1, pseudo_id2, decrypt_key, rawdata = @keystore.encrypt_record(key_name, :demographics, demog_json, @nhsnumber, @postcode, @birthdate, :create)
        decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, @nhsnumber, @postcode, @birthdate, :match)
        assert_equal(demog_json, decrypted_json)
        next unless dump_key_names.include?(key_name)

        puts <<~RUBY
          # Sample data for test 'decrypt existing data':
          ['#{key_name}', '#{demog_json}', '#{@nhsnumber}', '#{@birthdate}', '#{@postcode}',
           # '#{pseudo_id1}', # pseudo_id1
           # '#{pseudo_id2}', # pseudo_id2
           # #{decrypt_key.inspect}, # decrypt_key, before base64 encoding, #{decrypt_key.size} characters
           Base64.strict_decode64('#{Base64.strict_encode64(decrypt_key)}'), # decrypt_key
           # #{rawdata.inspect}, # rawdata, before base64 encoding, #{rawdata.size} characters
           Base64.strict_decode64('#{Base64.strict_encode64(rawdata)}')] # rawdata
        RUBY
      end
      skip 'TODO: Support extra key types in skip_keys' if skip_keys.present?
    end

    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    test 'decrypt existing data' do
      # To produce sample data, set dump_key_names in test 'encrypt and decrypt demographics' above.
      [
        ['unittest_pseudo_prescr', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE"}', '9999999468', '1925-01-27', 'B6 5RQ',
         # '050d0c4071f4b440c081ca70ad4e319989a03c2f32ea9e7c5719071b564aab0f', # pseudo_id1
         # nil, # pseudo_id2
         Base64.strict_decode64('IgnE6tl7TO/UqtQ+YRArlXtLns2zMPEp6qW0AmHHigc9MgKfbKg60kr09zvKWMWABdhv0lSM3RpdewdAu3fqabw3zwvxDm1aVQ5sQDfwvbQ='),
         Base64.strict_decode64('ROVQRsFNlC2VgXz0zg0Pik2isqWZ+RNEsTWaU/tejQrvH78D8OtERQWHqXfV8ELYw7nDEg6qMmrPueH9wKl95BaFgiX8ISlg8zNQefaS4OrY7xxXnMMp405rdE432KgFqCFEv5ChIzuwd3wKazDA129QcHMmxu+Kg9C+Dpp1X8A=')],
        ['unittest_encrypt', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE"}', '9999999468', '1925-01-27', 'B6 5RQ',
         # "2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9", # pseudo_id1
         # "dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3", # pseudo_id2
         # "\t~\x15\x02\x955\x92*\xA0qb\xAB\x0FN\xAC\xB5\xB1\x85\x84\xF9\xDF\xC2\xD3\x91\x96\xFCG\x82\"]5\xA4", # decrypt_key, before base64 encoding
         Base64.strict_decode64('CX4VApU1kiqgcWKrD06stbGFhPnfwtORlvxHgiJdNaQ='),
         # "C\xE3\xC8\x15*n \x9B\xA5\xBDR\xA8G%\x16f\xAE\xB9\x15\x83\xC3|\x95m}\xAD\x1Co\xF2\x9B\\\xFFy\xEF\xAD\xFBV\xFE<Lc\x9B\x9D{\xAF\xE4\x15\x90\xB1o\xA1\x11cu\xA7%\xCD\xC4P\xAEu7\x1A\x05\x1A\xDD\x14#\xB0\xCCa[Z\xEFyI\xD9\xD6K1\xCDS\xD3?\x1Dug\xCB\xD6\x01\x8CS\xDFJ\"m\v\xC5\x132\xDF:\xEF/\xDB\x97z\xBE\xBCU`\xEA\n~@\b\xE0(\xA6\xEA\x8Fv\xD4\xB6)\xEA\\L", # rawdata, before base64 encoding
         Base64.strict_decode64('Q+PIFSpuIJulvVKoRyUWZq65FYPDfJVtfa0cb/KbXP957637Vv48TGObnXuv5BWQsW+hEWN1pyXNxFCudTcaBRrdFCOwzGFbWu95SdnWSzHNU9M/HXVny9YBjFPfSiJtC8UTMt867y/bl3q+vFVg6gp+QAjgKKbqj3bUtinqXEw=')],
        ['unittest_pseudo_molecular', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE","blankfield":" "}', '9999999468', '1925-01-27', 'B6 5RQ',
         # '2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9', # pseudo_id1
         # 'dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3', # pseudo_id2
         # "\xBC\x9F\"\xD3l\x89\xA3\a_;\xDA\xEE\xE8)\xAB\xBA\x82z\x8C\xCEqiR5\xC6\x04'\xF9o\xC3\xE5\x87\xA1\xE0\xAB&\xD1\x97\xA4\x919\xA2C[T\x85\xF8\a\xCF\x14\xD7\xB3\xEBB\xF81\r\xD9\xC1v_M4\x9C\xE5%\x1D\xDD\aqz\xC3\xA0\x12%[j-\xE8\xCEE\xC6\xA9[\xF4M\x867\x1F\x9E\xE6AMt\x0Et\xCE+CM\x11\xB7\xB3\xF1\xA8Y\x9C\xFA\xF7\x023+x\x8FHW\x02\x8C\x94x\x82\xF7*R\xBD\v5\xD6\x84\xD5z\x01\x10\x1C\xE9\xB4B\xA9\x88=\xAC\xB6\xEC\xFA\xCBz\x9D[)\xFC^\x0F\x96k\xC3\x8A\xD7\xD1\xAA\x16u\xD3J\xFC\x83}\xB8\x84\x16\xEB\xAA|\x16}H:\x1D\xEE\xB6\a\xA2(\xB7!\xC8\xE9y\xDF\r<A\xC9\x99\xA7\xF5\xD4\xA5\xA0b\x8E\xD7|8d\xFF\x93\xB9\x97n@[M\eWd\xCE\xF8\x1A\xD0\xEC8c#\x86\xBC\xEA\x9D\x85_\xCD\x8Fl:C\x85\xFF\xEFMDC\x14\x92\x15\n\xF0~b\xC8\x9B\x8Dn^|\xAF\xFA\x92B\xE4k\xB8y\xD0#p\xFF\xAC\xCF>\xF5\x91\x98\xB0\xF2\xC9y[\x9B\xC8\xF2\x83`\xBC\"\x0F\xFCB\x8Ers@\xC6\xF3\xEB\x8E;\xA0\x8EC&\\v\xCE\x93D%\f\n\xC6\x86\xAB\xD7\x98\x89\tB\xC5\x9A\xA4'\x97", # decrypt_key, before base64 encoding, 320 characters
         Base64.strict_decode64('vJ8i02yJowdfO9ru6CmruoJ6jM5xaVI1xgQn+W/D5Yeh4Ksm0ZekkTmiQ1tUhfgHzxTXs+tC+DEN2cF2X000nOUlHd0HcXrDoBIlW2ot6M5Fxqlb9E2GNx+e5kFNdA50zitDTRG3s/GoWZz69wIzK3iPSFcCjJR4gvcqUr0LNdaE1XoBEBzptEKpiD2stuz6y3qdWyn8Xg+Wa8OK19GqFnXTSvyDfbiEFuuqfBZ9SDod7rYHoii3Icjped8NPEHJmaf11KWgYo7XfDhk/5O5l25AW00bV2TO+BrQ7DhjI4a86p2FX82PbDpDhf/vTURDFJIVCvB+YsibjW5efK/6kkLka7h50CNw/6zPPvWRmLDyyXlbm8jyg2C8Ig/8Qo5yc0DG8+uOO6COQyZcds6TRCUMCsaGq9eYiQlCxZqkJ5c='), # decrypt_key
         # "\xF1\xBDC\e\xF7\xBDt\xC3\x87\xB4\xADy\xD1\xF3\xBF |,\x0Fl\xDC\x1F\xE3Z\x88\xD7\xD2,o\x05I\xAC`\xF7\xBF\x1A\x80\xDF\v8c8ow\xCD\xB0\xF2T\n\x1D\xB1\xBD\x832\xF0\xAC\x87\ff\xBC\x13M9\x1A+\ao\xA0\x12\xB0\xBDlM\xD2\x87\xDD\x1A\x92s\x9D\aM_h\x86\xB5\x15y]\x96\x8E\xE61M/&\x06n!\x0E\xF4\x03+\xA3'\x06\x0E\x87\xD6(\xD5[\xB1\xFA\x92@%$7\xF7\xF6\xEC9\xF4\xF0\xBF\xADT\x10\xF4\xAD];\x8EW\xB0\xB6\tm[v\xC5O\xAB", # rawdata, before base64 encoding, 144 characters
         Base64.strict_decode64('8b1DG/e9dMOHtK150fO/IHwsD2zcH+NaiNfSLG8FSaxg978agN8LOGM4b3fNsPJUCh2xvYMy8KyHDGa8E005GisHb6ASsL1sTdKH3RqSc50HTV9ohrUVeV2WjuYxTS8mBm4hDvQDK6MnBg6H1ijVW7H6kkAlJDf39uw59PC/rVQQ9K1dO45XsLYJbVt2xU+r')] # rawdata
      ].each do |key_name, demographics, nhsnumber2, birthdate2, postcode2, decrypt_key, rawdata|
        decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, nhsnumber2, postcode2, birthdate2, :match)
        assert_equal(demographics, decrypted_json)
      end
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
