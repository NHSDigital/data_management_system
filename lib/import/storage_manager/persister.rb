require 'possibly'
require 'pry'

module Import
  module StorageManager
    # Aggregates individual genotype records into tests, results, and variants,
    # and insert them into the database. The key methods here are 'integrate_and_store',
    # which handles accumulating records in the correct structure, and 'finalize',
    # which is responsible for writing that structure into the database
    class Persister
      include Import::ImportKey

      def initialize(batch)
        @genetic_tests = {}
        @genetic_test_results = {}
        @genetic_sequence_variant = {}
        @duplicate_counter = 0
        @logger = Import::Log.get_logger
        @filter = DefaultFilter.new
        @e_batch = batch
        @reporter = PersisterReporter.new(self)
      end

      attr_reader :genetic_tests
      attr_reader :genetic_test_results
      attr_reader :genetic_sequence_variant

      def find_or_generate_test(genotype, tests_for_id)
        # NOTE: this is sneaky, and sets
        # the testing method to 'multiple' while returning 'true'
        #  if the records are otherwise similar - this is how Fiona
        # wanted to break the db scheme...
        test = tests_for_id.find { |cur_test| cur_test.similar!(genotype) }
        return test unless test.nil?

        cur_test = Import::DatabaseWrappers::GeneticTest.new(genotype)
        tests_for_id.push(cur_test)
        cur_test
      end

      def find_or_generate_result(genotype, results_for_test)
        # No longer merge results that shouldn't be merged! (It used to merge test statuses...)
        result = results_for_test.find { |cur_result| cur_result.similar?(genotype) }
        return result unless result.nil?

        cur_result = Import::DatabaseWrappers::GeneticTestResult.new(genotype)
        results_for_test.push(cur_result)
        cur_result
      end

      def find_or_generate_variant(genotype, variants_for_result)
        variant = variants_for_result.find { |cur_variant| cur_variant.similar!(genotype) }
        if variant
          @duplicate_counter += 1
          variant
        else
          cur_variant = Import::DatabaseWrappers::GeneticSequenceVariant.
          new(genotype)
          variants_for_result.push(cur_variant)
          cur_variant
        end
      end

      # This is the workhorse method, which creates tests, results, and variants for each line
      def integrate_and_store(genotype)
        return if @filter.invalid?(genotype)

        # ********************* Establish the test ***********************
        @genetic_tests[genotype.raw_record] = [] if @genetic_tests[genotype.raw_record].nil?
        tests_for_id = @genetic_tests[genotype.raw_record]
        test = find_or_generate_test(genotype, tests_for_id)

        # ********************* Establish the result ***********************
        @genetic_test_results[test] = [] if @genetic_test_results[test].nil?
        results_for_test = @genetic_test_results[test]
        result = find_or_generate_result(genotype, results_for_test)

        # ********************* Establish the variant ***********************
        @genetic_sequence_variant[result] = [] if @genetic_sequence_variant[result].nil?
        variants_for_result = @genetic_sequence_variant[result]
        find_or_generate_variant(genotype, variants_for_result)
      end

      # This is a stub to allow different providers to extend the storage handler and manage
      # how records are combined after accumulation on a provider-specific basis. Currently
      # not functional (or, relatedly, needed)
      def condense_results
        @genetic_test_results.each do |key, results|
          chunks = results.
          sort_by { |result|
            Maybe(result.representative_genotype.get('gene')).
            or_else(1)
            }.
            chunk { |result|
              Maybe(result.representative_genotype.get('gene')).
              or_else(-1)
            }
            @genetic_test_results[key] =
            chunks.map { |_num, res| Maybe(res.first).or_else([]) }
          end
        end

        def summarize_all
          @filter.summarize
          @reporter.print_duplicate_status
          @reporter.report_summary
        end

        def generate_patient(person)
          @e_batch.save!
          key_record = generate_key
          raw_data = Pseudo::PpatientRawdata.new('rawdata' => person.raw_all.to_s,
          'decrypt_key' => 'apple')
          # TODO: still don't have?
          raw_data.save!
          test_patient = Pseudo::Ppatient.new('pseudo_id1' => person.pseudo_id1,
          'pseudo_id2' => person.pseudo_id2,
          'ppatient_rawdata' => raw_data,
          'pseudonymisation_key' => key_record,
          'e_batch' => @e_batch)
          test_patient.save!
          test_patient
        end

        def generate_molecular_data(test_patient, test)
          moldata = Pseudo::MolecularData.
          new({ 'ppatient_id' => test_patient.id }.
          merge(test.produce_record))
          moldata.save!
          moldata
        end

        def generate_test_result(moldata, testresult)
          tresult = Pseudo::GeneticTestResult.
          new({ 'molecular_data' => moldata }.
          merge(testresult.produce_record))
          tresult.save!
          tresult
        end

        def generate_variant(var_record, tresult)
          variant_record = Pseudo::GeneticSequenceVariant.
          new({ 'genetic_test_result' => tresult }.
          merge(var_record))
          variant_record.save!
          variant_record
        end

        def generate_key
          key_record = Pseudo::PseudonymisationKey.new('key_name' => key) # from tab delimited
          key_record.save!
          key_record
        end

        def process_variants(variants, tresult)
          # Produce record for each variant, return as array
          variant_present = false
          variants.
          map(&:produce_record).
          reject(&:nil?).each do |var_record|
            generate_variant(var_record, tresult)
            variant_present = true
          end
          variant_present
        end

        def process_single_result(testresult, mdata)
          tresult = generate_test_result(mdata, testresult)
          variants = @genetic_sequence_variant[testresult]
          # p variants
          return if variants.nil?

          process_variants(variants, tresult)
          # TODO: this won't work if benign variants are considered 'normal'
          # p tresult.teststatus
          # variants_exist = process_variants(variants, tresult)
          # Pseudo::GeneticTestResult.update(tresult.id, 'teststatus' => 2) if variants_exist
        end

        def process_results(test, test_patient)
          mdata = generate_molecular_data(test_patient, test)
          results = @genetic_test_results[test]
          return if results.nil?

          results.each do |testresult|
            process_single_result(testresult, mdata)
          end
        end

        def process_tests(person, tests)
          test_patient = generate_patient(person)
          tests.each do |test|
            process_results(test, test_patient)
          end
        end

        def finalize
          # condense_results()
          summarize_all

          # Construct and write records to database
          @genetic_tests.each do |person, tests|
            process_tests(person, tests)
          end
          @logger.info 'Finished saving records to db'
        end
      end
    end
    end
