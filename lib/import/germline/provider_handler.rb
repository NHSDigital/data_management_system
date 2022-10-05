module Import
  module Germline
    # Base class from which all code which creates specialized, provider-specific
    # functionality originates
    class ProviderHandler
      def initialize(batch)
        @logger = Log.get_logger
        @lines_processed = 0
        @batch = batch
        attach_persister(batch)
      end

      def attach_persister(batch)
        @persister = Import::StorageManager::Persister.new(batch)
      end

      def finalize
        summarize
        @persister.finalize
      end

      def summarize; end

      def process_and_correct_fields(raw_record)
        @lines_processed += 1
        process_fields(raw_record)
      end

      def process_fields(_raw_record); end
    end
  end
end
