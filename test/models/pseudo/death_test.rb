require 'test_helper'

module Pseudo
  # Test creating / matching / decrypting Death data with demographics
  # c.f. Pseudo::PrescriptionTest
  class DeathTest < ActiveSupport::TestCase
    setup do
      # Sample demographics, that will produce pseudo_id1 and pseudo_id2 values
      @nhsnumber = '9999999468'
      @birthdate = '1925-01-27'
      @postcode = 'PE133AB'
      @demographics = { 'nhsnumber' => @nhsnumber, 'birthdate' => @birthdate,
                        'postcode' => @postcode }
      @key = 'unittest_encrypt'
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(KeyBundle.new)
      Ppatient.keystore = @keystore
      @e_batch = EBatch.new
      @nhsnumber2 = '9999999476'
      @birthdate2 = '1964-02-29'
      @postcode2 = 'OX4 2GX' # Spaces will be stripped in generating pseudo_id2
      @demographics2 = { 'nhsnumber' => @nhsnumber2, 'birthdate' => @birthdate2,
                         'postcode' => @postcode2 }
    end

    test 'create_from_demographics without rawtext' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      ppatient = Death.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
      assert(ppatient.valid?, ppatient.errors.to_hash)
      # Unlock demographics
      assert(ppatient.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(@demographics, ppatient.demographics)
      # Create a second ppatient with the same demographics, ensuring Ppatient_rawdata is reused
      ppatient.save!
      eb2 = EBatch.new
      fields_no_demog2 = { e_batch: eb2 }
      ppat2 = Death.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog2)
      assert_equal(ppatient.ppatient_rawdata, ppat2.ppatient_rawdata, 'Should re-use ppatient_rawdata')
      # Create a third ppatient with tweaked demographics, but same pseudo_id1
      demographics3 = @demographics.merge('surname' => 'EDITESTPATIENT', 'forenames' => 'ONE JOHN')
      ppat3 = Death.initialize_from_demographics(@key, demographics3, rawtext, fields_no_demog)
      assert(ppat3.valid?, ppat3.errors.to_hash)
      assert_equal(ppatient.pseudo_id1, ppat3.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat3.ppatient_rawdata, 'Should not re-use ppatient_rawdata for same pseudo_id1 but different demographics')

      # Because Pseudo::Death is using an encryption key, rather than an pseudonymisation key,
      # we can unlock it with the "wrong" demographics (but matching will still return sensible
      # results based on demographic comparison).
      assert(ppat3.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(demographics3, ppat3.demographics)
      assert(ppat3.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(demographics3, ppat3.demographics)
      # Create a fourth ppatient with different demographics, different pseudo_id1
      ppat4 = Death.initialize_from_demographics(@key, @demographics2, rawtext, fields_no_demog)
      assert(ppat4.valid?, ppat4.errors.to_hash)
      assert_not_equal(ppatient.pseudo_id1, ppat4.pseudo_id1)
      assert_not_equal(ppatient.ppatient_rawdata, ppat4.ppatient_rawdata, 'Should not re-use ppatient_rawdata for different demographics and different pseudo_id1')
      assert(ppat4.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(@demographics2, ppat4.demographics)
      assert(ppat4.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(@demographics2, ppat4.demographics)
    end

    # TODO: Support rawdata hash, and enable the following method:
    # test 'create_from_demographics with rawtext' do
    #   rawtext = { 'surname' => 'EDITESTPATIENT  ', 'forename1' => 'ONE', 'forename2' => 'JOHN' }
    #   fields_no_demog = { e_batch: @e_batch }
    #   ppatient = Death.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
    #   assert(ppatient.valid?, ppatient.errors.to_hash)
    #   # Unlock demographics
    #   assert(ppatient.unlock_demographics('', '', '', :match))
    #   assert_equal(@demographics, ppatient.demographics)
    # end

    # Match and unlock an existing, hard-wired record (check data format stable over time)
    test 'match_demographics with existing data' do
      rawdata = Base64.strict_decode64('+aPYyayHAGZu6gXyfjZ7Yz5+9hDRuE/Vgob2sI/LUSeX4Hz2oZTwINqMVZhgZEao1tcWQIDsqliY6V29PZYHhQ==')
      # ""\xF9\xA3\xD8\xC9\xAC\x87\x00fn\xEA\x05\xF2~6{c>~\xF6\x10\xD1\xB8O\xD5\x82\x86\xF6\xB0\x8F\xCBQ'\x97\xE0|\xF6\xA1\x94\xF0 \xDA\x8CU\x98`dF\xA8\xD6\xD7\x16@\x80\xEC\xAAX\x98\xE9]\xBD=\x96\a\x85"
      decrypt_key = Base64.strict_decode64('uEWFBi+OzqH30G4pahewgWL+fmZlRRX6tAqJWkdP+Cg=')
      # "\xB8E\x85\x06/\x8E\xCE\xA1\xF7\xD0n)j\x17\xB0\x81b\xFE~feE\x15\xFA\xB4\n\x89ZGO\xF8("
      assert_equal(32, decrypt_key.size, '256 bit symmetric key')
      ppatient_rawdata = PpatientRawdata.new(rawdata: rawdata, decrypt_key: decrypt_key)
      ppat = Prescription.new(pseudo_id1: '6c71062e85eac099505678f635c46a5a6f44a968bb93583fd857bd8a5ad4cc94',
                              pseudonymisation_key: PseudonymisationKey.find_by(key_name: @key),
                              ppatient_rawdata: ppatient_rawdata,
                              e_batch: @e_batch)
      ppat.save!
      assert_equal(:new, ppat.match_demographics(@nhsnumber, '', @birthdate))
      assert_equal(:fuzzy, ppat.match_demographics(@nhsnumber2, '', @birthdate))
      assert_equal(:perfect, ppat.match_demographics(@nhsnumber2, '', @birthdate2))
      # We can unlock it with blank demographics
      assert(ppat.unlock_demographics('', '', '', :match))
      old_demographics = { 'nhsnumber' => @nhsnumber2, 'birthdate' => @birthdate2 }
      assert_equal(old_demographics, ppat.demographics)
      # We can unlock it with the "wrong" demographics
      assert(ppat.unlock_demographics(@nhsnumber, '', @birthdate, :match))
      assert_equal(old_demographics, ppat.demographics)
      assert(ppat.unlock_demographics(@nhsnumber2, '', @birthdate2, :match))
      assert_equal(old_demographics, ppat.demographics)
    end

    # Ensure that find_matching_ppatients works as expected, when some patients have missing fields
    test 'find_matching_ppatients' do
      rawtext = nil
      fields_no_demog = { e_batch: @e_batch }
      ppatient1 = Death.initialize_from_demographics(@key, @demographics, rawtext, fields_no_demog)
      ppatient1.save!
      # Blank demographics
      ppatient2 = Death.initialize_from_demographics(@key, {}, rawtext, fields_no_demog)
      ppatient2.save!
      [true, false].each do |match_blank|
        [%w(nhsnumber), %w(birthdate), %w(postcode), %w(birthdate postcode),
         %w(nhsnumber birthdate postcode)].each do |fields|
          demog = @demographics.merge(fields.collect { |f| [f, ''] }.to_h)
          options = { match_blank: match_blank }
          pats = Ppatient.find_matching_ppatients(demog['nhsnumber'], demog['postcode'],
                                                  demog['birthdate'], nil, options)
          expect1 = demog.fetch('nhsnumber', '') == @demographics['nhsnumber'] ||
                    (demog.fetch('postcode', '') == @demographics['postcode'] &&
                     demog.fetch('birthdate', '') == @demographics['birthdate'])
          expect2 = match_blank &&
                    (demog.fetch('nhsnumber', '').blank? ||
                     (demog.fetch('postcode', '').blank? && demog.fetch('birthdate', '').blank?))
          expect_ids = [(ppatient1.id if expect1), (ppatient2.id if expect2)].compact
          expect_names = [('ppatient1' if expect1), ('ppatient2' if expect2)].compact
          assert_equal(expect_ids, pats.collect(&:id), "Expected [#{expect_names.join(', ')}], " \
                                                       "demog = #{demog}, options = #{options}")
        end
      end
    end

    test 'codt_codfft_extra for Model 204 / LEDR codt' do
      death = Death.new
      fields = (1..5).collect { |i| ["codt_#{i}".to_sym, "codt_#{i}"] }.to_h
      death.build_death_data(fields)
      (1..5).each { |i| assert_equal("codt_#{i}", death.codt_codfft_extra(i)) }
      (1..5).each { |i| assert_equal("codt_#{i}", death.codt_codfft_extra(i, 255)) }
      (1..4).each { |i| assert_equal("codt_#{i}", death.codt_codfft_extra(i, 255)) }
      # No need to append extra codfft text onto the last record
      assert_equal('codt_5', death.codt_codfft_extra(5, 255, true))
    end

    test 'codt_codfft_extra for LEDR codftt_1' do
      death = Death.new
      death.build_death_data(codfft_1: 'x' * (255 * 5 + 3))
      (1..5).each { |i| assert_equal('x' * 75, death.codt_codfft_extra(i)) }
      (1..5).each { |i| assert_equal('x' * 255, death.codt_codfft_extra(i, 255)) }
      (1..4).each { |i| assert_equal('x' * 255, death.codt_codfft_extra(i, 255)) }
      # Cannot append extra codfft text onto the last record, as it's already 255 characters long
      assert_equal('x' * 255, death.codt_codfft_extra(5, 255, true))
    end

    test 'codt_codfft_extra for Model 204 codftt_1 to codfft_65' do
      death = Death.new
      fields = (1..65).collect { |i| ["codfft_#{i}".to_sym, "codfft_#{i}"] }.to_h
      death.build_death_data(fields)
      (1..5).each { |i| assert_equal("codfft_#{i}", death.codt_codfft_extra(i)) }
      (1..5).each { |i| assert_equal("codfft_#{i}", death.codt_codfft_extra(i, 255)) }
      (1..4).each { |i| assert_equal("codfft_#{i}", death.codt_codfft_extra(i, 255)) }
      # Append extra codfft rows onto the last record, up to 255 characters
      # i.e. (5..65).collect { |i| "codfft_#{i}" }.join("\n")[0..254]
      assert_equal("codfft_5\ncodfft_6\ncodfft_7\ncodfft_8\ncodfft_9\ncodfft_10\ncodfft_11\n" \
                   "codfft_12\ncodfft_13\ncodfft_14\ncodfft_15\ncodfft_16\ncodfft_17\n" \
                   "codfft_18\ncodfft_19\ncodfft_20\ncodfft_21\ncodfft_22\ncodfft_23\n" \
                   "codfft_24\ncodfft_25\ncodfft_26\ncodfft_27\ncodfft_28\ncodfft_29\ncodfft_30\n",
                   death.codt_codfft_extra(5, 255, true))
      assert_equal("codfft_5\ncodfft_6\ncodfft_7\ncodfft_8\ncodfft_9\ncodfft_10\ncodfft_11\n" \
                   "codfft_12\n", death.codt_codfft_extra(5, 75, true))
    end
  end
end
