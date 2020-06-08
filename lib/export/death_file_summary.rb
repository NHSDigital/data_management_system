module Export
  # Extract summary statistics for a death batch
  class DeathFileSummary < DeathFileSimple
    def initialize(filename, e_type, ppats, filter = nil, ppatid_rowids: nil)
      super
      @stats = Hash.new(0)
      %w[e_batch_ids e_batch_digests e_batch_original_filenames].each { |w| @stats[w] = Set.new }
    end

    private

    # Empty list of fields, as nothing needs to be extracted
    def fields
      []
    end

    def extract_row(ppat, _)
      return unless super # Skip rows according to standard criteria

      @stats['e_batch_ids'] << ppat.e_batch.id
      @stats['e_batch_digests'] << ppat.e_batch.digest
      @stats['e_batch_original_filenames'] << ppat.e_batch.original_filename
      @stats['deaths'] += 1
      neonatal = ppat.neonatal?
      england = extract_field(ppat, 'pod_in_england') == 1
      @stats['deaths_non_neonatal'] += 1 unless neonatal
      if england
        @stats['deaths_england'] += 1
        @stats['deaths_england_non_neonatal'] += 1 unless neonatal
      end
      dor_year = extract_field(ppat, 'doryr')
      @stats["deaths_dor_year_#{dor_year}"] += 1
      nil # don't emit anything for each row; everything comes out in the footer
    end

    def header_rows
      [%w[STATISTIC VALUE]]
    end

    def footer_rows(_)
      @stats.collect { |k, v| [k, v.to_json] }.sort
    end
  end
end
