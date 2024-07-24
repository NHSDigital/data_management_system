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

      def add_provider_code(genotype, record, org_code_map)
        raw_org = record.raw_fields['providercode']&.downcase&.strip
        org_code = org_code_map[raw_org]
        return if org_code.blank?

        genotype.attribute_map['providercode'] = org_code
      end
    end
  end
end
