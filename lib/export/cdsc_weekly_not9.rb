module Export
  # Export and de-pseudonymises weekly CDSC data (excluding surveillance code CDSC09)
  class CdscWeeklyNot9 < CdscWeekly
    def initialize(filename, e_type, ppats)
      super
      @surveillance_codes -= ['CDSC09']
    end
  end
end
