require 'ndr_import/table'
require 'ndr_import/file/registry'
require 'json'
require 'pry'
require 'csv'

# folder = File.expand_path('../', __dir__)
# $LOAD_PATH.unshift(folder) unless $LOAD_PATH.include?(folder)


module Import
  module Brca
    module Core
      # Use the record processing step to pass records to the main importer backend
      class BrcaMainlineImporter < BrcaBase
        def insert_e_batch_digest(batch)
          batch.update(digest: digest)
        end

        # Get the SHA1 digest of the source
        def digest
          return nil if file.nil?

          @digest ||= Digest::SHA1.file(SafeFile.safepath_to_string(@filename)).hexdigest
        end

        # Fail early if the source file has already been loaded.
        def ensure_file_not_already_loaded
          clashes = EBatch.where('digest = ? and e_batchid != ?', digest, @batch.id)
          error_message = 'Source file already loaded: See e_batchid: ' \
                          "#{clashes.map(&:id).join(', ')}"
          raise error_message if clashes.any?
        end

        def process_records(_klass, fields)
          raise "Unknown e_type #{@batch.e_type}" if @batch.e_type != 'PSMOLE'

          # Parse JSON fields, and pass of to handler to extract and store relevant fields
          if fields.size > 2
            @handler.process_and_correct_fields(RawRecord.new(fields))
          else
            @logger.warn "Skipping record with fewer than two fields: #{fields}"
          end
        end

        def load
          # Set the EBatch.digest
          insert_e_batch_digest(@batch) if file
          @handler = Import::Brca::Core::BrcaHandlerMapping.
                     get_handler(@batch.provider).
                     new(@batch)
          super
          @handler.finalize
        end
      end
    end
  end
end
