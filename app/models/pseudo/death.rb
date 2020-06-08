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
        next unless (line || DeathData::COD10R_TO_LINENO9[cod10r]) == i
        multiple_cause_code(j)
      end
      causes.compact
    end

    # Textual reference to identify record ppatientid, mbism204id / ledrid
    def record_reference
      "ppatientid #{id}, " + (if demographics['ledrid'] then "LEDRID #{demographics['ledrid']}"
                              else "MBISM204ID #{demographics['mbism204id']}"
                              end)
    end
  end
end
