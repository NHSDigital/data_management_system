require 'ndr_import/table'
require 'ndr_import/file/registry'

module Export
  # Export and de-pseudonymises delimited MBIS data
  # (in the original file format)
  class DelimitedFile
    def initialize(filename, e_type, ppats)
      @filename = filename
      @e_type = e_type
      @ppats = ppats
      @col_fields = table_mapping.columns.collect do |col|
        [col['column'], col['mappings'].find { |map| map.key?('field') }['field']]
      end
      # Successor fields: if the next field is populated, emit this field as a single space.
      @successor = {}
      last_field = nil
      @col_fields.each do |_col, field|
        @successor[last_field] = field if last_field&.start_with?('codfft_') &&
                                          field.start_with?('codfft_')
        last_field = field
      end if @e_type == 'PSDEATH'
    end

    # Export data to file, returns number of records emitted
    def export
      i = 0
      CSV.open(@filename, 'wb', **csv_options) do |csv|
        header_rows.each { |row| csv << row }
        # Prefer data from demographics to DeathData, in case identifiable fields
        # are in demographics, but accidentally also listed in DeathData table.
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        @ppats.includes(@e_type == 'PSDEATH' ? :death_data : :birth_data,
                        :ppatient_rawdata).send(meth) do |ppat|
          csv << extract_row(ppat)
          i += 1
        end
        # Print footer rows
        footer_rows(i).each { |row| csv << row }
      end
      i
    end

    private

    # Load the required mapping file based on @batch.e_type
    def table_mapping
      # TODO: Refactor with Import::DelimitedFile#table_mapping
      # TODO: Decide on e_type names
      # mapping_file = 'death_mapping.yml'
      mapping_file = case @e_type
                     when 'PSDEATH'
                       'deaths_mapping.yml'
                     when 'PSBIRTH'
                       'births_mapping.yml'
                     else
                       raise "No mapping found for #{@batch.e_type}"
                     end

      YAML.load_file(SafePath.new('mappings_config').join(mapping_file))
    end

    # Header rows (including weird capitalisations of some fields)
    def header_rows
      if @e_type == 'PSDEATH'
        [
          [' '],
          @col_fields.collect do |col, _field|
            case col
            when 'record id' then 'Record ID'
            when /(D[1-3]|4I)[abcde]$/i then col[0..-2].upcase + col[-1..-1].downcase
            when '' then nil # Avoid emitting "" as blank column headings
            else col.upcase
            end
          end
        ]
      else
        [
          [' '],
          @col_fields.collect do |col, _field|
            col.upcase
          end
        ]
      end
    end

    def footer_rows(i)
      if @e_type == 'PSDEATH'
        [["COUNT IN = #{i}"],
         ["COUNT OT = #{i}"]]
      else []
      end
    end

    def csv_options
      { col_sep: '|', row_sep: "\r\n", force_quotes: @e_type != 'PSDEATH' }
    end

    def extract_row(ppat)
      ppat.unlock_demographics('', '', '', :export)
      @col_fields.collect do |_col, field|
        val = if ppat.demographics.key?(field)
                ppat.demographics[field]
              elsif ppat.has_attribute?(field)
                ppat[field]
              elsif ppat.death_data && ppat.death_data.has_attribute?(field)
                ppat.death_data[field]
              elsif ppat.birth_data && ppat.birth_data.has_attribute?(field)
                ppat.birth_data[field]
              end # else nil implicit
        # Some fields were blank, but replaced with single spaces
        # (icdfuture1 and icdfuture2 are not space filled, to match ONS extract)
        val ||= @e_type == 'PSDEATH' ? ' ' : '   ' if 'ledrid' == field
        val ||= ' ' if %w(loapod lsoapod wigwo10 wigwo10f loar).include?(field)
        val ||= '         ' if %w(loarpob lsoarpob loarm).include?(field)
        # Multi-line death text has single-space rows whenever a later row is non-blank
        # (Currently just doing lookahead of 3 here, but arbitrary value may be required)
        val = ' ' if val.nil? && @successor.key?(field) && (
                       ppat.death_data[@successor[field]] ||
                       (@successor.key?(@successor[field]) && (
                          ppat.death_data[@successor[@successor[field]]] ||
                          (@successor.key?(@successor[@successor[field]]) &&
                           ppat.death_data[@successor[@successor[@successor[field]]]]))))
        val
      end
    end
  end
end
