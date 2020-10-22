require 'test_helper'

class ColorectalMainlineImporterTest < ActiveSupport::TestCase
  test 'ensure load creates expected records and logging' do
    assert Pseudo::GeneticTestResult.count.zero?
    assert Pseudo::GeneticSequenceVariant.count.zero?

    e_batch  = e_batch(:colorectal_batch)
    filename = safe_path_for(e_batch.original_filename)
    importer = Import::Colorectal::Core::ColorectalMainlineImporter.new(filename, e_batch)
    assert_difference('Pseudo::MolecularData.count', + 2) do
      assert_difference('Pseudo::GeneticTestResult.count', + 2) do
        assert_difference('Pseudo::GeneticSequenceVariant.count', + 1) do
          @importer_stdout, @importer_stderr = capture_io do
            importer.load
          end
        end
      end
    end

    assert @importer_stderr.blank?
    logs = @importer_stdout.split("\n")

    expected_logs = [
      '(WARN) Cannot extract exon from: NP_000240.1:p.(Glu23LysfsTer13)',
      '(ERROR) Input: 0 given for variant class of impropertype (Integer), or out of range',
      '(WARN) Genomic change did not match expected format,adding raw: NC_000003.11:',
      '(WARN) Cannot extract exon from: NP_000240.1:',
      '(INFO) Num genes failed to parse: 0 of 2 tests being attempted',
      '(INFO) Num genes successfully parsed: 2 of2 attempted',
      '(INFO) Num genocolorectals failed to parse: 1of 2 attempted',
      '(INFO) Num positive tests: 1of 2 attempted',
      '(INFO) Num negative tests: 1of 2 attempted',
      '(INFO) Filter rejected 0 of2 genotypes seen',
      '(INFO) Num patients: 2',
      '(INFO) Num genetic tests: 2',
      '(INFO) Num test results: 2',
      '(INFO) Num sequence variants: 2',
      '(INFO) Num true variants: 1',
      '(INFO) Num duplicates encountered: ',
      '(INFO) Finished saving records to db'
    ]

    expected_logs.each { |expected_log| assert_includes(logs, expected_log) }

    molecular_data_record_one = Pseudo::MolecularData.find_by(servicereportidentifier: 'ABC123')
    assert_equal 'Provider One', molecular_data_record_one.providercode
    assert_equal 'Consultant One', molecular_data_record_one.practitionercode
    assert_equal 45, molecular_data_record_one.age

    molecular_data_record_two = Pseudo::MolecularData.find_by(servicereportidentifier: 'XYZ789')
    assert_equal 'Provider Two', molecular_data_record_two.providercode
    assert_equal 'Consultant Two', molecular_data_record_two.practitionercode
    assert_equal 70, molecular_data_record_two.age

    assert Pseudo::GeneticTestResult.negative.one?
    negative_test = Pseudo::GeneticTestResult.negative.first
    assert_equal '1432', negative_test.gene
    assert negative_test.genetic_sequence_variants.count.zero?

    assert Pseudo::GeneticTestResult.positive.one?
    positive_test = Pseudo::GeneticTestResult.positive.first
    assert_equal '2744', positive_test.gene
    assert positive_test.genetic_sequence_variants.one?
    variant = positive_test.genetic_sequence_variants.first
    assert_equal 'c.67del', variant.codingdnasequencechange
    assert_equal 'p.Glu23LysfsTer13', variant.proteinimpact
    assert_equal 5, variant.variantpathclass
    assert_equal 3, variant.sequencevarianttype
  end

  test 'ensure manchester data is grouped and loaded correctly' do
    assert Pseudo::GeneticTestResult.count.zero?
    assert Pseudo::GeneticSequenceVariant.count.zero?

    e_batch  = e_batch(:r0a_colorectal_batch)
    filename = safe_path_for(e_batch.original_filename)
    importer = Import::Colorectal::Core::ColorectalMainlineImporter.new(filename, e_batch)
    assert_difference('Pseudo::MolecularData.count', + 2) do
      assert_difference('Pseudo::GeneticTestResult.count', + 4) do
        assert_difference('Pseudo::GeneticSequenceVariant.count', + 1) do
          @importer_stdout, @importer_stderr = capture_io do
            importer.load
          end
        end
      end
    end

    assert @importer_stderr.blank?
    logs = @importer_stdout.split("\n")

    expected_logs = [
      '(INFO) Filter rejected 0 of4 genotypes seen',
      '(INFO)  *************** Duplicate status report *************** ',
      '(INFO) [1, 1]',
      '(INFO) [3, 1]',
      '(INFO) ***************** Storage Report *******************',
      '(INFO) Num patients: 2',
      '(INFO) Num genetic tests: 2',
      '(INFO) Num test results: 4',
      '(INFO) Num sequence variants: 4',
      '(INFO) Num true variants: 1',
      '(INFO) Num duplicates encountered: ',
      '(INFO) Finished saving records to db'
    ]

    expected_logs.each { |expected_log| assert_includes(logs, expected_log) }

    assert_equal 3, Pseudo::GeneticTestResult.negative.count
    assert Pseudo::GeneticTestResult.positive.one?

    positive_test = Pseudo::GeneticTestResult.positive.first
    assert_equal 6, positive_test.geneticaberrationtype
    assert_equal '2808', positive_test.gene
    assert_nil positive_test.age

    expected_authorised_dates         = ['2012-11-12 00:00:00']
    expected_servicereportidentifiers = ['000000']

    raw_records = JSON.parse(positive_test.raw_record)
    # Testing that all rows of data relating the the same test are considered
    assert_equal 59, raw_records.count
    assert_equal expected_authorised_dates, raw_records.map { |raw| raw['authoriseddate'] }.uniq
    assert_equal expected_servicereportidentifiers,
                 raw_records.map { |raw| raw['servicereportidentifier'] }.uniq

    assert positive_test.genetic_sequence_variants.one?
    variant = positive_test.genetic_sequence_variants.first
    assert_equal 'c.81C>G', variant.codingdnasequencechange
    assert_equal 'p.Ala27Ala', variant.proteinimpact
    assert_equal 1, variant.sequencevarianttype
    variant_raw_records = JSON.parse(variant.raw_record)
    assert_equal expected_authorised_dates,
                 variant_raw_records.map { |raw| raw['authoriseddate'] }.uniq

    assert_equal expected_servicereportidentifiers,
                 raw_records.map { |raw| raw['servicereportidentifier'] }.uniq
  end

  private

  def safe_path_for(filename)
    SafePath.new('test_files', filename)
  end
end
