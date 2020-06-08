module Export
  # Extract summary statistics for a death batch
  class CestrssrSummary < DeathFileSimple
    include Helpers::SimpleSummary

    private

    def summary_fields
      %w[cestrssr ceststay cestrss esttyped icdu_icduf
         nhsind agecunit agec lsoar sex_statistical doryr] +
        (1..20).collect { |i| "multiple_cause_code_#{i}" }
      # CESTRSSR            -- Col 3, Communal establishment code of Place of residence
      # ,CESTSTAY            -- Col 4, Length of Stat in communal establishment
      # ,CESTRSS             -- Col 6, Communal establishment code (RSS)
      # ,ESTTYPED           -- Col 58, Establishment type where death occurred
      # ,ICDUF                   -- Col 144 Final Underlying cause code - non neonatal deaths only
      # ,NHSIND                 -- Col 189 NHS Establishment Indicator
      # ,AGEC                    -- Col 197 Age
      # ,AGECUNIT            -- Col 198 AgeCUnit
      # ,LSOAR                  -- Col 244 Local super output area of usual residence
      # ,SEX                       -- Col 261 Sex
      # ,Year(DOR)             -- Col 297 Date of registration
      # ,Count(*)                 -- Count of deaths with this combination of values
      # %w[e_batch_ids e_batch_digests e_batch_original_filenames].each { |w| @stats[w] = Set.new }
    end
  end
end
