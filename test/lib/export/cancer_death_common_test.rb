require 'test_helper'

# rubocop:disable Naming/VariableNumber
module Export
  class CancerDeathCommonTest < ActiveSupport::TestCase
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

    # Helper constructor for a patient with codt, icd and cod10r fields but no codfft
    # (LEDR style, with no cause 1d)
    def codt_icd_ppat_and_fields_without_cause1d
      fields_no_demog = { codt_1: 'Cause 1' * 86, codt_2: '222', codt_3: '333',
                          codt_4: '4' * 75, codt_5: 'cause 5',
                          icd_1: 'A01', cod10r_1: 'a',
                          icd_2: 'B01', cod10r_2: 'b',
                          icd_3: 'C01', cod10r_3: 'c',
                          icd_4: 'D01', cod10r_4: 'd',
                          icd_5: 'E01', cod10r_5: 'e',
                          icd_6: 'E02', cod10r_6: 'e',
                          icd_7: 'A002', cod10r_7: 'a',
                          icd_8: 'B002', cod10r_8: 'b',
                          icd_9: 'C002', cod10r_9: 'c',
                          icd_10: 'D002', cod10r_10: 'd',
                          icd_11: 'E003', cod10r_11: 'e',
                          icd_12: 'E004', cod10r_12: 'e',
                          icd_13: 'X01', cod10r_13: '11', # historic ONS_CODE field
                          icd_14: 'X002', cod10r_14: '12', # historic ONS_CODE field
                          icdu: 'U01',
                          icdsc: 'S01' }
      ppat = build_death_record(fields_no_demog)
      [ppat, fields_no_demog]
    end

    # Helper constructor for a patient with codt, icd and cod10r fields but no codfft
    # (LEDR style, with cause 1d)
    def codt_icd_ppat_and_fields_with_cause1d
      fields_no_demog = { codt_1: 'Cause 1' * 86, codt_2: '222', codt_3: '333',
                          codt_4: '4' * 75, codt_5: 'cause 5', codt_6: 'cause 1d',
                          icd_1: 'A01', cod10r_1: 'a',
                          icd_2: 'B01', cod10r_2: 'b',
                          icd_3: 'C01', cod10r_3: 'c',
                          icd_4: 'D01', cod10r_4: 'd',
                          icd_5: 'E01', cod10r_5: 'e',
                          icd_6: 'F01', cod10r_6: 'f',
                          icd_7: 'A002', cod10r_7: 'a',
                          icd_8: 'B002', cod10r_8: 'b',
                          icd_9: 'C002', cod10r_9: 'c',
                          icd_10: 'D002', cod10r_10: 'd',
                          icd_11: 'E002', cod10r_11: 'e',
                          icd_12: 'F002', cod10r_12: 'f',
                          icd_13: 'X01', cod10r_13: '11', # historic ONS_CODE field
                          icd_14: 'X002', cod10r_14: '12', # historic ONS_CODE field
                          icdu: 'U01',
                          icdsc: 'S01' }
      ppat = build_death_record(fields_no_demog)
      [ppat, fields_no_demog]
    end

    def build_death_record(fields_no_demog)
      rawtext = nil # No rawtext preserved for death data
      ppat = Pseudo::Death.initialize_from_demographics(@key, @demographics, rawtext, e_batch: @e_batch)
      ppat.build_death_data(fields_no_demog)
      ppat
    end

    def extract_cancer_death_csv(ppats)
      ppat_scope = Pseudo::Ppatient.where(id: ppats.collect(&:id))
      outdata = Tempfile.create do |outfile|
        extractor = CancerDeathWeekly.new(outfile.path, 'PSDEATH', ppat_scope, 'all')
        extractor.export
        outfile.read
      end
      CSV.parse(outdata, headers: true)
    end

    test 'match CARA ICD codes' do
      should_match = %w[D821 Q012 Q262 Q605]
      should_match.each do |icd|
        assert_match Export::CancerDeathCommon::CARA_PATTERN, icd
      end
    end

    test 'reject non-CARA ICD codes' do
      should_reject = %w[A020 D823 P524 Q250 Q038 Q039 Q336 Q658 Q673] + ['']
      should_reject.each do |icd|
        assert_no_match Export::CancerDeathCommon::CARA_PATTERN, icd
      end
    end

    test 'should extract cancer death record fields for deaths with no cause 1d' do
      ppat, fields = codt_icd_ppat_and_fields_without_cause1d
      ppat.save(validate: false)
      outcsv = extract_cancer_death_csv([ppat])
      assert_equal(1, outcsv.size)
      row = outcsv[0].to_h
      assert_equal(34, row.size)

      assert_equal(fields[:codt_1], row['ONS_TEXT1A'], 'ONS_TEXT1A')
      assert_equal(fields[:codt_2], row['ONS_TEXT1B'], 'ONS_TEXT1B')
      assert_equal(fields[:codt_3], row['ONS_TEXT1C'], 'ONS_TEXT1C')
      assert_equal(fields[:codt_4], row['ONS_TEXT2'], 'ONS_TEXT2')
      assert_equal(fields[:codt_5], row['ONS_TEXT'], 'ONS_TEXT')
      assert_equal('A01,A002', row['ONS_CODE1A'], 'ONS_CODE1A')
      assert_equal('B01,B002', row['ONS_CODE1B'], 'ONS_CODE1B')
      assert_equal('C01,C002', row['ONS_CODE1C'], 'ONS_CODE1C')
      assert_equal('D01,E01,E02,D002,E003,E004', row['ONS_CODE2'], 'ONS_CODE2')
      assert_equal('X01,X002', row['ONS_CODE'], 'ONS_CODE')
      assert_equal('U01', row['DEATHCAUSECODE_UNDERLYING'], 'DEATHCAUSECODE_UNDERLYING')
      assert_equal('S01', row['DEATHCAUSECODE_SIGNIFICANT'], 'DEATHCAUSECODE_SIGNIFICANT')
    end

    test 'should extract cancer death record fields for deaths with cause 1d' do
      ppat, fields = codt_icd_ppat_and_fields_with_cause1d
      ppat.save(validate: false)
      outcsv = extract_cancer_death_csv([ppat])
      assert_equal(1, outcsv.size)
      row = outcsv[0].to_h
      assert_equal(34, row.size)

      assert_equal(fields[:codt_1], row['ONS_TEXT1A'], 'ONS_TEXT1A')
      assert_equal(fields[:codt_2], row['ONS_TEXT1B'], 'ONS_TEXT1B')
      assert_equal("#{fields[:codt_3]}, #{fields[:codt_6]}", row['ONS_TEXT1C'], 'ONS_TEXT1C')
      assert_equal(fields[:codt_4], row['ONS_TEXT2'], 'ONS_TEXT2')
      assert_equal(fields[:codt_5], row['ONS_TEXT'], 'ONS_TEXT')
      assert_equal('A01,A002', row['ONS_CODE1A'], 'ONS_CODE1A')
      assert_equal('B01,B002', row['ONS_CODE1B'], 'ONS_CODE1B')
      assert_equal('C01,F01,C002,F002', row['ONS_CODE1C'], 'ONS_CODE1C')
      assert_equal('D01,E01,D002,E002', row['ONS_CODE2'], 'ONS_CODE2')
      assert_equal('X01,X002', row['ONS_CODE'], 'ONS_CODE')
      assert_equal('U01', row['DEATHCAUSECODE_UNDERLYING'], 'DEATHCAUSECODE_UNDERLYING')
      assert_equal('S01', row['DEATHCAUSECODE_SIGNIFICANT'], 'DEATHCAUSECODE_SIGNIFICANT')
    end
  end
end
# rubocop:enable Naming/VariableNumber
