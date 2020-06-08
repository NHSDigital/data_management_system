require 'pdf-reader'
require 'ndr_support/safe_file'
require 'ndr_import/file/registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a PoC PDF AcroForm PDF file handler that returns a single table comprised of
    # a header row and a single data row.
    class AcroForm < Base
      private

      def rows(&block)
        return enum_for(:rows) unless block

        data = reader.acroform_data
        [data.keys, data.values].each(&block)
      rescue NoMethodError
        raise "Failed to read #{SafeFile.basename(@filename)} as an AcroForm PDF"
      end

      def reader
        @reader ||= PDF::Reader.new(SafeFile.safepath_to_string(@filename))
      end
    end

    Registry.register(AcroForm, 'acroform')
  end
end
