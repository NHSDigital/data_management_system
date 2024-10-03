require 'test_helper'

# rubocop:disable Naming/VariableNumber
module Export
  class DeathFileTest < ActiveSupport::TestCase
    def setup
      @nhsnumber = '9999999468'
      @birthdate = '1925-01-27'
      @postcode = 'PE133AB'
      @demographics = { 'nhsnumber' => @nhsnumber, 'birthdate' => @birthdate,
                        'postcode' => @postcode }
      @key = 'unittest_encrypt'
      ENV['MBIS_KEK'] = 'test'
      @keystore = Pseudo::KeyStoreLocal.new(Pseudo::KeyBundle.new)
      Pseudo::Ppatient.keystore = @keystore
    end

    def build_death_record(fields_no_demog)
      rawtext = nil # No rawtext preserved for death data
      ppat = Pseudo::Death.initialize_from_demographics(@key, @demographics, rawtext, e_batch: @e_batch)
      ppat.build_death_data(fields_no_demog)
      ppat
    end

    # Helper constructor for a patient with a multiple 75-character codfft fields (Model 204-style)
    def short_codfft_ppat_and_fields
      # codfft_1 .. codfft_6 populated, all 75 characters or less
      fields_no_demog = { codfft_1: '1A) 123456', codfft_2: '1B) 7890', codfft_3: '1C) UNKNOWN',
                          codfft_4: '2) "Goes here"', codfft_5: 'More info', codfft_6: 'And more',
                          codfft_7: 'Even more' }
      ppat = build_death_record(fields_no_demog)
      [ppat, fields_no_demog]
    end

    # Helper constructor for a patient with a single long codfft_1 (LEDR-style)
    def long_codfft_ppat_and_fields
      # codfft_1 is 456 characters = (75 * 6) + 6 = 6 * 76
      fields_no_demog = { codfft_1: '123456' * 76, codt_1: 'Will be ignored' }
      ppat = build_death_record(fields_no_demog)
      [ppat, fields_no_demog]
    end

    # Helper constructor for a patient with codt fields but no codfft (Model 204 or LEDR style)
    def codt_ppat_and_fields
      fields_no_demog = { codt_1: 'Cause 1' * 86, codt_2: '222', codt_3: '333',
                          codt_4: '4' * 75, codt_5: 'cause 5', codt_6: 'cause 1d' }
      ppat = build_death_record(fields_no_demog)
      [ppat, fields_no_demog]
    end

    # Helper method, to test private field extraction method
    def extract_field(ppat, field, klass = DeathFile)
      death_file = klass.new('dummy', 'PSDEATH', [ppat])
      ppat.unlock_demographics('', '', '', :export) # Allow access to all demographics
      death_file.send(:extract_field, ppat, field)
    end

    test 'extract long CODFFT over CODT and split into 75 character sections' do
      ppat, fields = long_codfft_ppat_and_fields
      assert(fields[:codfft_1].size > 75 * 5,
             'Expect codfft_1 to span more than 5 blocks of 75 characters')

      assert_equal(fields[:codfft_1][0..74], extract_field(ppat, 'codt_codfft_1'))
      assert_equal(fields[:codfft_1][75..149], extract_field(ppat, 'codt_codfft_2'))
      assert_equal(fields[:codfft_1][150..224], extract_field(ppat, 'codt_codfft_3'))
      assert_equal(fields[:codfft_1][225..299], extract_field(ppat, 'codt_codfft_4'))
      assert_equal(fields[:codfft_1][300..374], extract_field(ppat, 'codt_codfft_5'))
      assert_equal(fields[:codfft_1][375..449], extract_field(ppat, 'codt_codfft_6'))
      # There is no codt_7, but codt_codfft_7 can be used to get codfft_6 (from Model 204 data),
      # or to get more of CODFFT in 75-character instalments (from LEDR data)
      assert_equal(fields[:codfft_1][450..], extract_field(ppat, 'codt_codfft_7'))
    end

    test 'extract long CODFFT over CODT and split into 255 character sections' do
      ppat, fields = long_codfft_ppat_and_fields
      assert(fields[:codfft_1].size > 255 * 1,
             'Expect codfft_1 to span more than 1 blocks of 255 characters')

      assert_equal(fields[:codfft_1][0..254], extract_field(ppat, 'codt_codfft_1_255'))
      assert_equal(fields[:codfft_1][255..-1], extract_field(ppat, 'codt_codfft_2_255'))
      assert_nil(extract_field(ppat, 'codt_codfft_3_255'))
      assert_nil(extract_field(ppat, 'codt_codfft_4_255'))
      assert_nil(extract_field(ppat, 'codt_codfft_5_255extra'))
    end

    test 'extract short CODFFT over CODT' do
      ppat, fields = short_codfft_ppat_and_fields

      assert_equal(fields[:codfft_1], extract_field(ppat, 'codt_codfft_1'))
      assert_equal(fields[:codfft_2], extract_field(ppat, 'codt_codfft_2'))
      assert_equal(fields[:codfft_3], extract_field(ppat, 'codt_codfft_3'))
      assert_equal(fields[:codfft_4], extract_field(ppat, 'codt_codfft_4'))
      assert_equal(fields[:codfft_5], extract_field(ppat, 'codt_codfft_5'))
      assert_equal(fields[:codfft_6], extract_field(ppat, 'codt_codfft_6'))
    end

    test 'extract short CODFFT over CODT split into 255 character sections' do
      ppat, fields = short_codfft_ppat_and_fields

      assert_equal(fields[:codfft_1], extract_field(ppat, 'codt_codfft_1_255'))
      assert_equal(fields[:codfft_2], extract_field(ppat, 'codt_codfft_2_255'))
      assert_equal(fields[:codfft_3], extract_field(ppat, 'codt_codfft_3_255'))
      assert_equal(fields[:codfft_4], extract_field(ppat, 'codt_codfft_4_255'))
      assert_equal(fields[:codfft_5] + "\n" + fields[:codfft_6] + "\n" + fields[:codfft_7],
                   extract_field(ppat, 'codt_codfft_5_255extra'))
    end

    test 'extract CODT if no CODFFT' do
      ppat, fields = codt_ppat_and_fields

      assert_equal(fields[:codt_1], extract_field(ppat, 'codt_codfft_1'))
      assert_equal(fields[:codt_2], extract_field(ppat, 'codt_codfft_2'))
      assert_equal(fields[:codt_3], extract_field(ppat, 'codt_codfft_3'))
      assert_equal(fields[:codt_4], extract_field(ppat, 'codt_codfft_4'))
      assert_equal(fields[:codt_5], extract_field(ppat, 'codt_codfft_5'))
      assert_equal(fields[:codt_6], extract_field(ppat, 'codt_codfft_6'))
      assert_nil(extract_field(ppat, 'codt_codfft_7'))
    end

    test 'extract CODT if no CODFFT split into 255 character sections' do
      ppat, fields = codt_ppat_and_fields

      assert_equal(fields[:codt_1], extract_field(ppat, 'codt_codfft_1_255'))
      assert_equal(fields[:codt_2], extract_field(ppat, 'codt_codfft_2_255'))
      assert_equal(fields[:codt_3], extract_field(ppat, 'codt_codfft_3_255'))
      assert_equal(fields[:codt_4], extract_field(ppat, 'codt_codfft_4_255'))
      assert_equal(fields[:codt_5], extract_field(ppat, 'codt_codfft_5_255extra'))
      assert_equal(fields[:codt_6], extract_field(ppat, 'codt_codfft_6_255'))
      assert_nil(extract_field(ppat, 'codt_codfft_7'))
    end

    test 'extract CODT_3 and CODT_6 combined in old-style cancer extracts' do
      ppat, fields = codt_ppat_and_fields

      assert_equal("#{fields[:codt_3]}, #{fields[:codt_6]}",
                   extract_field(ppat, 'codt_codfft_3_codt_6_255'))
    end
  end
end
# rubocop:enable Naming/VariableNumber
