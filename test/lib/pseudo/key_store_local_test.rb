require 'test_helper'

module Pseudo
  class KeyStoreLocalTest < ActionDispatch::IntegrationTest
    setup do
      @nhsnumber = '9999999468'
      @surname = 'EDITTESTPATIENT'
      @forenames = 'ONE'
      @birthdate = '1925-01-27'
      @postcode = 'B6 5RQ'
      @blankfield = ' ' # Test a demographic field that has value ' ', i.e. blank but not empty.
      @key_names = %w(unittest_pseudo_prescr unittest_encrypt)
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
    end

    test 'pseudo_ids' do
      # Returns an array, where each element contains [key, pseudo_id1, pseudo_id2]
      pseudo_ids_list = @keystore.pseudo_ids(@key_names, @nhsnumber, @postcode, @birthdate, :match)
      assert_equal([['unittest_pseudo_prescr',
                     '050d0c4071f4b440c081ca70ad4e319989a03c2f32ea9e7c5719071b564aab0f', nil],
                    %w(unittest_encrypt
                       2c372acb575d58603d9fc27c3f9afac0694719db2ab843a93636ee3019b902f9
                       dca8c390cc232ee4f762d2af3ba65e7f19079ab339a437d62c03a7bb672da4e3)],
                   pseudo_ids_list)
    end

    test 'encrypt and decrypt demographics' do
      skip_keys = []
      @key_names.each do |key_name|
        next if skip_keys.include?(key_name)
        demog_hash = { 'nhsnumber' => @nhsnumber, 'postcode' => @postcode, 'birthdate' => @birthdate, 'surname' => @surname, 'forenames' => @forenames, 'blankfield' => @blankfield }
        demog_json = demog_hash.to_json
        _pseudo_id1, _pseudo_id2, decrypt_key, rawdata = @keystore.encrypt_record(key_name, :demographics, demog_json, @nhsnumber, @postcode, @birthdate, :create)
        decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, @nhsnumber, @postcode, @birthdate, :match)
        assert_equal(demog_json, decrypted_json)
      end
      skip 'TODO: Support extra key types in skip_keys' if skip_keys.present?
    end

    # rubocop:disable Metrics/ParameterLists # Lightweight API for trusted crypto support
    test 'decrypt existing data' do
      [['unittest_pseudo_prescr', '{"nhsnumber":"9999999468","postcode":"B6 5RQ","birthdate":"1925-01-27","surname":"EDITTESTPATIENT","forenames":"ONE"}', '9999999468', '1925-01-27', 'B6 5RQ',
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
        Base64.strict_decode64('Q+PIFSpuIJulvVKoRyUWZq65FYPDfJVtfa0cb/KbXP957637Vv48TGObnXuv5BWQsW+hEWN1pyXNxFCudTcaBRrdFCOwzGFbWu95SdnWSzHNU9M/HXVny9YBjFPfSiJtC8UTMt867y/bl3q+vFVg6gp+QAjgKKbqj3bUtinqXEw=')]].each do |key_name, demographics, nhsnumber2, birthdate2, postcode2, decrypt_key, rawdata|
        decrypted_json = @keystore.decrypt_record(key_name, :demographics, decrypt_key, rawdata, nhsnumber2, postcode2, birthdate2, :match)
        assert_equal(demographics, decrypted_json)
      end
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
