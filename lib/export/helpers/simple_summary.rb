module Export
  module Helpers
    # Mixin for simple aggregate results for birth / death files (like SQL "GROUP BY")
    # To use, define a DeathFileSimple / BirthFileSimple subclass, then
    # include Helpers::SimpleSummary
    module SimpleSummary
      def initialize(filename, e_type, ppats, filter = nil, ppatid_rowids: nil)
        super
        @stats = Hash.new(0)
        @summary_fields = summary_fields
        @requires_demographics = requires_demographics?
      end

      private

      # Empty list of fields, as nothing needs to be extracted
      def fields
        []
      end

      def summary_fields
        raise 'Override this method in a subclass'
      end

      # Can be overridden to return false, if only non-identifying data fields are needed
      def requires_demographics?
        true
      end

      def extract_row(ppat, _)
        return unless super # Skip rows according to standard criteria

        ppat.unlock_demographics('', '', '', :export) if @requires_demographics
        key = @summary_fields.collect { |field| extract_field(ppat, field) }
        @stats[key] += 1
        nil # don't emit anything for each row; everything comes out in the footer
      end

      def match_row?(ppat, _surveillance_code = nil)
        return false unless extract_field(ppat, 'pod_in_england') == 1

        super
      end

      def header_rows
        [@summary_fields + ['count']]
      end

      def footer_rows(_)
        # Treat nils as empty strings, convert numbers to strings to ensure sorting works
        @stats.collect { |k, v| k.collect(&:to_s) + [v.to_json] }.sort.
          collect { |row| row.collect { |s| s == '' ? nil : s } } # Map empty string back to nil
      end
    end
  end
end
