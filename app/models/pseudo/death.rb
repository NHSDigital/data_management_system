module Pseudo
  # Patient death record (MBIS)
  class Death < Ppatient
    validates_associated :death_data

    # Neonatal - deaths under 28 days.
    def neonatal?
      # Units age stored in (1 = years, 2 = months, 3 = weeks, 4 = days < 7)
      # (001-011 months, 001-004 weeks, 000-006 days)
      # Model 204 provided agec with leading zeros, LEDR provides it without
      death_data['agecunit'] == 4 ||
        (death_data['agecunit'] == 3 && %w(001 002 003 1 2 3).include?(demographics['agec']))
    end

    # Indefinite date of birth indicator
    def indefinite_date_of_birth?
      demographics['dobdy'] == '00' || demographics['dobmt'] == '00'
    end

    # Patient age, in integer years
    def age_in_years
      death_data['agecunit'] == 1 ? demographics['agec'].to_i : 0
    end

    # ICD10F if present, else ICD10PVF, else ICD10, else ICD10PV
    def multiple_cause_code(i)
      raise 'Invalid index' unless (1..20).include?(i)
      death_data.send("icdf_#{i}") || death_data.send("icdpvf_#{i}") ||
        death_data.send("icd_#{i}") || death_data.send("icdpv_#{i}")
    end

    # Array of death cause codes that match the corresponding line from the text
    #
    # In LEDR, cause codes have moved from being in a mixture of lineno9f_... / lineno9_... fields,
    # and cod10rf_... / cod10r_... fields, to exclusively cod10rf_... / cod10r_... fields.
    def matched_cause_codes(i)
      raise 'Invalid index' unless (1..6).include?(i)

      # lineno values are always 1-6
      causes = (1..20).collect do |j|
        cod10r = death_data.send("cod10rf_#{j}") || death_data.send("cod10r_#{j}")
        line = death_data.send("lineno9f_#{j}") || death_data.send("lineno9_#{j}")
        # More recent deaths have inconsistently back-ported lineno values from cod10r values
        line = nil if cod10r && line && death_data.dor.to_i >= 20180206 #  diffs
        # Prefer old lineno9 value, for continuity, and because it's more finegrained
        raise 'New death cause 1d not yet supported' if cod10r == 'f'

        next unless (line || DeathData::COD10R_TO_LINENO9[cod10r]) == i

        multiple_cause_code(j)
      end
      causes.compact
    end

    # Extract codt or codfft field, splitting long LEDR codfft_1, and merge extra
    # codfft rows if necessary into the final record.
    def codt_codfft_extra(i, chunk_size = 75, merge_extra = false)
      raise 'Invalid index' unless (1..65).include?(i)
      raise 'Invalid chunk_size' unless chunk_size >= 75
      raise 'merge_extra supported only for i >= 5' if merge_extra && i < 5

      # LEDR workaround: split long CODFFT_1 into 75+ character blocks to support older extracts.
      # In LEDR extracts, CODFFT_1 is often >= 75 characters, and CODFFT_2..CDOFFT_65 are blank
      codfft = death_data.codfft_1
      return codfft[(i - 1) * chunk_size..(i * chunk_size) - 1] if codfft && codfft.size > 75

      result = death_data["codfft_#{i}"] || (death_data["codt_#{i}"] if i <= 5)
      return result unless merge_extra

      ([result] + (i + 1..65).collect { |j| death_data["codfft_#{j}"] }).
        compact.join("\n")[0..chunk_size - 1]
    end

    # Textual reference to identify record ppatientid, mbism204id / ledrid
    def record_reference
      "ppatientid #{id}, " + (if demographics['ledrid'] then "LEDRID #{demographics['ledrid']}"
                              else "MBISM204ID #{demographics['mbism204id']}"
                              end)
    end
  end
end
