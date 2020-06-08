require 'import/storage_manager/persister'
require 'import/database_wrappers/genetic_sequence_variant'
require 'core/database_wrappers/genetic_test_result'
require 'core/database_wrappers/genetic_test'
require 'core/database_wrappers/genotype_wrapper'
module Newcastle
  # Make Newcastle-specific changes to storage behavior
  class NewcastlePersister < Import::Brca::Core::StorageManager::Persister
    def process_results(test, test_patient)
      md = generate_molecular_data(test_patient, test)
      results = @genetic_test_results[test]
      return if results.nil?

      if results.size == 1 &&
         results.
         first.
         representative_genotype.
         full_screen?
        real_result = results.first
        new_genotype = Import::Brca::Core::Genotype.new(real_result.
                                      representative_genotype.
                                      raw_record)
        new_genotype.add_status(:normal)
        new_genotype.add_gene(real_result.
                                representative_genotype.
                                other_gene)

        results.append(Import::Brca::Core::DatabaseWrappers::GeneticTestResult.new(new_genotype))
      end
      results.each do |testresult|
        process_single_result(testresult, md)
      end
    end
  end
end
