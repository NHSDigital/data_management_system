module Import
  module Helpers
    # Helper methods, for inclusion into rake tasks
    module RakeHelper
      # Helpers to import birth / death files
      module FileImporter
        # Import a batch of birth / death data, with automatic rollback of failures caused by bad
        # files. Return the e_batch on success, or return nil on rollback of common errors
        # (if keep) instead of throwing exceptions.
        def self.import_mbis_and_rollback_failures(original_filename, e_type, keep)
          file_name = SafePath.new('mbis_data').join(original_filename)
          # EBatch.digest set in Import::DelimitedFile#load
          # Attempt to re-use existing batch, if previous batch import failed because the file
          # was missing / had wrong permissions (and therefore has no digest).
          e_batch = EBatch.find_or_create_by(original_filename: original_filename, e_type: e_type,
                                             provider: 'XDC04', registryid: 'XDC04', digest: nil)

          # ??? Add progress monitoring block parameter
          begin
            Import::DelimitedFile.new(file_name, e_batch).load
          rescue CSV::MalformedCSVError => e
            raise e if keep && e_batch.ppatients.any? # Rethrow
            puts 'ERROR: Invalid CSV file format: aborting and rolling back.'
            puts "#{e.class}: #{e.message}"
            e_batch.destroy
            return nil
          rescue RuntimeError => e
            raise e if keep && !e.message.start_with?('Source file already loaded')
            puts 'ERROR: Aborting and rolling back.'
            puts "#{e.class}: #{e.message}"
            e_batch.destroy
            return nil
          end
          # puts "Created #{e_batch.e_type} EBatch #{e_batch.id} with #{e_batch.ppatients.count} " \
          #      'records'
          e_batch
        end
      end
    end
  end
end
