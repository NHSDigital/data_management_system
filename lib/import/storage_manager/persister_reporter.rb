require 'possibly'
require 'pry'
module Import
  module StorageManager
    # Externalize summarization for the Persister
    class PersisterReporter
      def initialize(persister)
        @logger = Import::Log.get_logger
        @persister = persister
      end

      def num_tests
        @persister.genetic_tests.values.flatten.size
      end

      def num_patients
        @persister.genetic_tests.values.flatten.size
      end

      def num_results
        @persister.genetic_test_results.values.flatten.size
      end

      def num_raw_variants
        @persister.genetic_sequence_variant.values.flatten.size
      end

      def num_true_variant
        @persister.genetic_sequence_variant.
        values.
        flatten.
        map(&:produce_record).
        reject(&:nil?).
        size
      end

      def report_summary
        @logger.info '***************** Storage Report *******************'
        @logger.info "Num patients: #{num_patients}"
        @logger.info "Num genetic tests: #{num_tests}"
        @logger.info "Num test results: #{num_results}"
        @logger.info "Num sequence variants: #{num_raw_variants}"
        @logger.info "Num true variants: #{num_true_variant}"
        @logger.info "Num duplicates encountered: #{@duplicate_counter}"
      end

      def print_duplicate_status
        @logger.info ' *************** Duplicate status report *************** '
        @persister.genetic_test_results.map { |_key, value| value.size }.sort.chunk { |n| n }.
        map { |x, y| [x, Maybe(y).map(&:size).or_else(-1)] }.
        each do |x|
          @logger.info x
        end
      end
    end
  end
end
