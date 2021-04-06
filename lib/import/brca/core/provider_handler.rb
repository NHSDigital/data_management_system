
module Import
  module Brca
    module Core
      # Base class from which all code which creates specialized, provider-specific
      # functionality originates
      class ProviderHandler
        def initialize(batch)
          @logger = Log.get_logger
          @lines_processed = 0
          @batch = batch
          attach_persister(batch)
          @preprocessor = CorrectionPreprocessor.from_batch(batch)
          @preprocess_enabled = !@preprocessor.nil?
        end

        def attach_persister(batch)
          @persister = Import::StorageManager::Persister.new(batch)
        end

        def finalize
          @preprocessor.summarize if @preprocess_enabled
          summarize
          @persister.finalize
        end

        def summarize; end

        def process_and_correct_fields(raw_record)
          @lines_processed += 1
          @preprocessor.apply_correction(raw_record) if @preprocess_enabled
          process_fields(raw_record)
        end

        def process_fields(_raw_record); end
      end
    end
  end
end
