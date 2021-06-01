require 'test_helper'

module Pseudo
  # Test creating / matching / decrypting Death data with demographics
  # c.f. Pseudo::PrescriptionTest
  class MolecularTest < ActiveSupport::TestCase
    setup do
      # Sample demographics, that will produce pseudo_id1 and pseudo_id2 values
      @nhsnumber = '9999999468'
      @birthdate = '1925-01-27' # More than 14 years from @birthdate2, i.e. :veryfuzzy match
      @postcode = 'PE133AB'
      @demographics = { 'nhsnumber' => @nhsnumber, 'birthdate' => @birthdate,
                        'postcode' => @postcode }
      # Using the same pseudonymisation keys for BRCA as for births and deaths
      # (although used in encrypting mode for births and deaths, pseudonymising only for BRCA)
      @key = 'unittest_pseudo_molecular'
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
      Ppatient.keystore = @keystore
      @e_batch = EBatch.new
      @nhsnumber2 = '9999999476'
      @birthdate2 = '1964-02-29'
      @postcode2 = 'OX4 2GX' # Spaces will be stripped in generating pseudo_id2
      @demographics2 = { 'nhsnumber' => @nhsnumber2, 'birthdate' => @birthdate2,
                         'postcode' => @postcode2 }
      @birthdate3 = '1963-01-01' # Less than 14 years from @birthdate2, i.e. :fuzzy match
    end

    test 'create_from_demographics without rawtext' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      ppatient = Molecular.initialize_from_demographics(@key, @demographics, rawtext,
                                                        fields_no_demog)
      assert(ppatient.valid?, ppatient.errors.to_hash)

      # Unlock demographics with nhsnumber
      assert_raises(ArgumentError, 'Demographics should be locked') { ppatient.demographics }
      assert(ppatient.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(@demographics, ppatient.demographics)
      # Create a second ppatient with the same demographics, ensuring Ppatient_rawdata is reused
      ppatient.save!
      eb2 = EBatch.new
      fields_no_demog2 = { e_batch: eb2 }
      ppat2 = Molecular.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog2)
      assert_equal(ppatient.ppatient_rawdata, ppat2.ppatient_rawdata,
                   'Should re-use ppatient_rawdata')

      assert_raises(ArgumentError, 'Demographics should be locked') { ppat2.demographics }
      assert(ppat2.unlock_demographics('', @postcode, @birthdate, :match),
             'Should unlock demographics with postcode and birthdate')
      assert_equal(@demographics, ppat2.demographics)

      # Create a third ppatient with tweaked demographics, but same pseudo_id1
      demographics3 = @demographics.merge('surname' => 'EDITESTPATIENT', 'forenames' => 'ONE JOHN')
      ppat3 = Molecular.initialize_from_demographics(@key, demographics3, rawtext, fields_no_demog)
      assert(ppat3.valid?, ppat3.errors.to_hash)
      assert_equal(ppatient.pseudo_id1, ppat3.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat3.ppatient_rawdata,
                       'Should not re-use ppatient_rawdata for same pseudo_id1 but different ' \
                       'demographics')

      # Because Pseudo::Molecular is using a pseudonymisation key, rather than an encryption key,
      # we cannot unlock it with the "wrong" demographics (but matching will still return sensible
      # results based on demographic comparison).
      refute(ppat3.unlock_demographics(@nhsnumber2, '', @birthdate2, :match),
             'Should not be able to unlock with different demographics')
      assert_raise(ArgumentError, 'Expected demographics still to be locked') do
        assert_equal(demographics3, ppat3.demographics)
      end
      assert(ppat3.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(demographics3, ppat3.demographics)
      # Create a fourth ppatient with different demographics, different pseudo_id1
      ppat4 = Molecular.initialize_from_demographics(@key, @demographics2, rawtext, fields_no_demog)
      assert(ppat4.valid?, ppat4.errors.to_hash)
      assert_not_equal(ppatient.pseudo_id1, ppat4.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat4.ppatient_rawdata,
                       'Should not re-use ppatient_rawdata for different demographics and ' \
                       'different pseudo_id1')
      refute(ppat4.unlock_demographics(@nhsnumber, '', @birthdate, :match),
             'Should not be able to unlock with different demographics')
      assert_raise(ArgumentError, 'Expected demographics still to be locked') do
        assert_equal(@demographics2, ppat4.demographics)
      end
      assert(ppat4.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(@demographics2, ppat4.demographics)
    end

    # TODO: Support rawdata hash, and enable the following method:
    # test 'create_from_demographics with rawtext' do
    #   rawtext = { 'surname' => 'EDITESTPATIENT  ', 'forename1' => 'ONE', 'forename2' => 'JOHN' }
    #   fields_no_demog = { e_batch: @e_batch }
    #   ppatient = Molecular.initialize_from_demographics(@key, @demographics, rawtext,
    #                                                     fields_no_demog)
    #   assert(ppatient.valid?, ppatient.errors.to_hash)
    #   # Unlock demographics
    #   assert(ppatient.unlock_demographics('', '', '', :match))
    #   assert_equal(@demographics, ppatient.demographics)
    # end

    # Match and unlock an existing, hard-wired record (check data format stable over time)
    # TODO: write test 'match_demographics with existing data' do
    # end

    test 'match_demographics with new data' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      ppat = Molecular.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
      ppat.save!
      assert_raise(ArgumentError, 'Demographics should be locked') { ppat.demographics }
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber, @postcode, @birthdate))
      ppat.lock_demographics
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber, '', @birthdate))
      ppat.lock_demographics
      assert_raise(ArgumentError, 'Demographics should be locked') { ppat.demographics }
      assert_equal(:veryfuzzy, ppat.match_demographics(@nhsnumber, '', @birthdate2))
      ppat.lock_demographics
      assert_equal(:new, ppat.match_demographics('', '', @birthdate))
      ppat.lock_demographics
      assert_equal(:fuzzy_postcode, ppat.match_demographics('', @postcode, @birthdate))
    end

    test 'match_demographics with ISO dateofbirth in demographics' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      demographics3 = { 'nhsnumber' => @nhsnumber,
                        'dateofbirth' => "#{@birthdate}T00:00:00.000+00:00",
                        'postcode' => @postcode }
      ppat = Molecular.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
      # Replace ppat.ppatient_rawdata with demographics3, i.e. use dateofbirth instead of birthdate
      demog_json = demographics3.to_json
      _pseudo_id1, _pseudo_id2, decrypt_key, rawdata = \
        @keystore.encrypt_record(@key, :demographics, demog_json, @nhsnumber, @postcode, @birthdate,
                                 :create)
      ppat.ppatient_rawdata = PpatientRawdata.new(decrypt_key: decrypt_key, rawdata: rawdata)
      ppat.save!
      assert_raise(ArgumentError, 'Demographics should be locked') { ppat.demographics }
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber, @postcode, @birthdate))
      ppat.lock_demographics
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber, '', @birthdate))
      ppat.lock_demographics
      assert_raise(ArgumentError, 'Demographics should be locked') { ppat.demographics }
      assert_equal(:veryfuzzy, ppat.match_demographics(@nhsnumber, '', @birthdate2))
      ppat.lock_demographics
      assert_equal(:new, ppat.match_demographics('', '', @birthdate))
      ppat.lock_demographics
      assert_equal(:fuzzy_postcode, ppat.match_demographics('', @postcode, @birthdate))
    end

    # Ensure that find_matching_ppatients works as expected, when some patients have missing fields
    # TODO: write test 'find_matching_ppatients' do
    # end
  end
end
