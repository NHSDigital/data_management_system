module Export
  # Export and de-pseudonymises weekly CDSC data (surveillance code CDSC09 only)
  class CdscWeekly9 < CdscWeekly
    def initialize(filename, e_type, ppats)
      super
      @surveillance_codes &= ['CDSC09']
    end
  end
end
