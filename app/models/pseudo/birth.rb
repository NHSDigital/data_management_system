module Pseudo
  # Patient birth record (MBIS)
  class Birth < Ppatient
    # Textual reference to identify record ppatientid, mbism204id / ledrid
    def record_reference
      "ppatientid #{id}, " + (if demographics['ledrid'] then "LEDRID #{demographics['ledrid']}"
                              else "MBISM204ID #{demographics['mbism204id']}"
                              end)
    end
  end
end
