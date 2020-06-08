require 'test_helper'

module Pseudo
  # Test creating / matching / decrypting Prescription data with demographics
  # c.f. Pseudo::DeathTest
  class PrescriptionTest < ActiveSupport::TestCase
    setup do
      @nhsnumber = '9999999468'
      @birthdate = '1925-01-27'
      @demographics = { 'nhsnumber' => @nhsnumber, 'birthdate' => @birthdate }
      @key = 'unittest_pseudo_prescr'
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
      Ppatient.keystore = @keystore
      @e_batch = EBatch.new
      @nhsnumber2 = '9999999476'
      @birthdate2 = '1964-02-29'
      @demographics2 = { 'nhsnumber' => @nhsnumber2, 'birthdate' => @birthdate2 }
    end

    test 'create_from_demographics without rawtext' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      ppatient = Prescription.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
      assert(ppatient.valid?, ppatient.errors.to_hash)
      # Unlock demographics
      assert(ppatient.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(@demographics, ppatient.demographics)
      # Create a second ppatient with the same demographics, ensuring Ppatient_rawdata is reused
      ppatient.save!
      eb2 = EBatch.new
      fields_no_demog2 = { e_batch: eb2 }
      ppat2 = Prescription.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog2)
      assert_equal(ppatient.ppatient_rawdata, ppat2.ppatient_rawdata, 'Should re-use ppatient_rawdata')
      # Create a third ppatient with tweaked demographics, but same pseudo_id1
      demographics3 = @demographics.merge('surname' => 'EDITESTPATIENT', 'forenames' => 'ONE JOHN')
      ppat3 = Prescription.initialize_from_demographics(@key, demographics3, rawtext, fields_no_demog)
      assert(ppat3.valid?, ppat3.errors.to_hash)
      assert_equal(ppatient.pseudo_id1, ppat3.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat3.ppatient_rawdata, 'Should not re-use ppatient_rawdata for same pseudo_id1 but different demographics')
      assert_not(ppat3.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_raises(ArgumentError) { ppat3.demographics }
      assert(ppat3.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(demographics3, ppat3.demographics)
      # Create a fourth ppatient with different demographics, different pseudo_id1
      ppat4 = Prescription.initialize_from_demographics(@key, @demographics2, rawtext, fields_no_demog)
      assert(ppat4.valid?, ppat4.errors.to_hash)
      assert_not_equal(ppatient.pseudo_id1, ppat4.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat4.ppatient_rawdata, 'Should not re-use ppatient_rawdata for different demographics and different pseudo_id1')
      assert_not(ppat4.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_raises(ArgumentError) { ppat4.demographics }
      assert(ppat4.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(@demographics2, ppat4.demographics)
    end

    # Match and unlock an existing, hard-wired record (check data format stable over time)
    test 'match_demographics with existing data' do
      rawdata = Base64.strict_decode64('M8oA5pUb0TusCb+3rRlBAqBbWknriybyCxamL6jUO1aVH/gi9KYavGibJa1v13CG2G4q1sWOai9DYbkw1MSNgg==')
      # "3\xCA\x00\xE6\x95\e\xD1;\xAC\t\xBF\xB7\xAD\x19A\x02\xA0[ZI\xEB\x8B&\xF2\v\x16\xA6/\xA8\xD4;V\x95\x1F\xF8\"\xF4\xA6\x1A\xBCh\x9B%\xADo\xD7p\x86\xD8n*\xD6\xC5\x8Ej/Ca\xB90\xD4\xC4\x8D\x82"
      decrypt_key = Base64.strict_decode64('Gv0/7/JYEx4iPwKiU4AhySczonJLLGf0q1Q2tid+iLA0wO2rQwJXV+B41g+Dwtlgtf++c0sulNe7sJEvGuErzDFjSqMaRpKr8R9GTsVoMeE=')
      # "\x1A\xFD?\xEF\xF2X\x13\x1E\"?\x02\xA2S\x80!\xC9'3\xA2rK,g\xF4\xABT6\xB6'~\x88\xB04\xC0\xED\xABC\x02WW\xE0x\xD6\x0F\x83\xC2\xD9`\xB5\xFF\xBEsK.\x94\xD7\xBB\xB0\x91/\x1A\xE1+\xCC1cJ\xA3\x1AF\x92\xAB\xF1\x1FFN\xC5h1\xE1"
      ppatient_rawdata = PpatientRawdata.new(rawdata: rawdata, decrypt_key: decrypt_key)
      ppat = Prescription.new(pseudo_id1: '6c71062e85eac099505678f635c46a5a6f44a968bb93583fd857bd8a5ad4cc94',
                              pseudonymisation_key: PseudonymisationKey.find_by(key_name: @key),
                              ppatient_rawdata: ppatient_rawdata,
                              e_batch: @e_batch)
      ppat.save!
      assert_equal(:new, ppat.match_demographics(@nhsnumber, '', @birthdate))
      assert_equal(:fuzzy, ppat.match_demographics(@nhsnumber2, '', @birthdate))
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber2, '', @birthdate2))
      assert_not(ppat.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert(ppat.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(@demographics2, ppat.demographics)
    end
  end
end
