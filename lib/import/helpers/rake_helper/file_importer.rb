module Import
  module Helpers
    # Helper methods, for inclusion into rake tasks
    module RakeHelper
      # Helpers to import birth / death files
      module FileImporter
        # Import a batch of birth / death data, with automatic rollback of failures caused by bad
        # files. Return the e_batch on success, or return nil on rollback of common errors
        # (if keep) instead of throwing exceptions.
        def self.import_mbis_and_rollback_failures(original_filename, e_type,
                                                   keep:, ignore_footer:)
          file_name = SafePath.new('mbis_data').join(original_filename)
          raise "ERROR: Cannot import missing file #{file_name}" unless File.exist?(file_name)

          unless ignore_footer
            last_line = nil
            File.foreach(file_name) { |line| last_line = line }
            unless /\ATotal of Extracted records = [0-9]+\z/.match?(last_line&.chomp)
              raise 'ERROR: Not importing file with missing footer row - possibly truncated?'
            end
          end

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

        # Import all outstanding batches of weekly birth / death data.
        # Raises an exception when trying to import any incomplete files
        # Otherwise returns the number of newly imported files
        def self.import_weekly(e_types, logger: Rails.logger)
          imported = 0
          e_types.each do |e_type|
            pattern = case e_type
                      when 'PSBIRTH' then 'private/mbis_data/births/MBISWEEKLY_Births_B[0-9]*.txt'
                      when 'PSDEATH' then 'private/mbis_data/deaths/MBISWEEKLY_Deaths_D[0-9]*.txt'
                      else raise "Unsupported e_type #{e_type}"
                      end
            Dir.glob(pattern).sort.each do |fname0|
              fname_stripped = fname0.sub('private/mbis_data/', '')
              filename = SafePath.new('mbis_data').join(fname_stripped)
              # Has the file already been imported (same filename or digest)?
              digest = Digest::SHA1.file(SafeFile.safepath_to_string(filename)).hexdigest
              if EBatch.where(e_type: e_type).
                 exists?(['original_filename = ? or digest = ?', fname_stripped, digest])
                # logger.debug("Skipping already imported file #{fname_stripped.inspect}")
                next
              end

              # Will raise an exception if the file is unreadable or missing a footer
              # Will return nil if the file cannot be imported
              begin
                e_batch = import_mbis_and_rollback_failures(fname_stripped, e_type,
                                                            keep: false, ignore_footer: false)
                raise 'ERROR: failure importing file' if e_batch.nil?
              rescue RuntimeError
                logger.warn("ERROR: Cannot import #{e_type} file #{fname_stripped.inspect}")
                raise "ERROR: Cannot import file #{fname_stripped.inspect}"
              end
              imported += 1
              logger.warn("Successfully imported #{e_type} file #{fname_stripped.inspect} as " \
                          "e_batchid #{e_batch.id}")
            end
          end
          imported
        end
      end
    end
  end
end
