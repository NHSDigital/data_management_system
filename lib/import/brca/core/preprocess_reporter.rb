require 'csv'

module Import
  module Brca
    module Core
      # Template for how the preprocess can be hooked in to output a processed version of the
      # original file only, rather than intercepting rawrecords and passing them on to the importer;
      # this is essentially just a tool if you want to see what happened after processing
      class PreprocessReporter
        def initialize(filename, batch)
          super(filename, batch)
          @preprocessor = Import::Brca::Core::CorrectionPreprocessor.from_batch(batch)
        end

        def write_corrected_file
          # Set up export file
          target_filename = ''
          @output_file = CSV.open(target_filename, 'w')
          file << headers
          load
          @output_file.close
        end

        def process_records(_klass, fields, _handler)
          raise "Unknown e_type #{@batch.e_type}" if @batch.e_type != 'PSMOLE'

          # Parse JSON fields, and pass of to handler to extract and store relevant fields
          if fields.size > 2
            record = Import::Brca::Core::RawRecord.new(fields)
            @preprocessor.apply_correction(record)
            # TODO: write the record to file
          else
            @logger.warn "Skipping record with fewer than two fields: #{fields}"
          end
        end
      end
    end
  end
end
