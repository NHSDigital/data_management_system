module Import
  module Colorectal
    module Providers
      module Newcastle
        # Make Newcastle-specific changes to storage behavior
        class NewcastlePersister < Import::StorageManager::Persister
          def process_results(test, test_patient)
            md = generate_molecular_data(test_patient, test)
            results = @genetic_test_results[test]
            return if results.nil?

            results.each do |testresult|
              process_single_result(testresult, md)
            end
          end
        end
      end
    end
  end
end
