module Export
  # Export and de-pseudonymise annual Viral Hepatitis death extract
  # Specification file: "Viral Hepititis 2016.pdf"
  # Specification updated in plan.io #9852:
  # Can you re run the 2016 extract but with the following fields only:
  # dester podt icd9_icd10 icd9f_icd10f icd9sc_icd10sc icd9scf_icd10scf icd9u_icd10u
  # icd9uf_icd10uf pcdpod doddy dodmt dodyr pcdr dobdy dobmt dobyr sex linen09_lneno10
  # lineno9f_lneno10f codt agec ctrypob occtype pobt occhft occmt dor occdt cod10r cod10rf
  #  ctryr ctyr occfft codfft
  class ViralHepatitisDeathsFile2 < DeathFileSimple
    # Codes extracted are C22*, I85*, I982, B15* to B19* or K70* to K77* or R16 to R189
    SURVEILLANCE_PATTERN = /\A(C22|I85|I982|B1[5-9]|K7[0-7]|R1[6-8])/.freeze

    def initialize(filename, e_type, ppats, filter = nil)
      super
      # Fields to check for matches
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w[icduf]
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w[icdu]
      @icd_fields_all = @icd_fields_f + @icd_fields
    end

    private

    def fields
      %w[dester podt] +
        (1..20).collect { |i| "icd_#{i}" } +
        (1..20).collect { |i| "icdf_#{i}" } +
        %w[icdsc icdscf icdu icduf pcdpod doddy dodmt dodyr pcdr dobdy dobmt dobyr
           sex_statistical] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
        (1..5).collect { |i| "codt_#{i}" } +
        %w[agec ctrypob occtype pobt occhft occmt dor occdt] +
        (1..20).collect { |i| "cod10r_#{i}" } +
        (1..20).collect { |i| "cod10rf_#{i}" } +
        %w[ctryr ctyr] +
        (1..65).collect { |i| "occfft_#{i}" } +
        (1..65).collect { |i| "codfft_#{i}" }
    end

    def match_row?(ppat, _surveillance_code = nil)
      # TODO: Refactor with match_row? in CancerDeathWeekly / CdscWeekly
      pattern = self.class::SURVEILLANCE_PATTERN # Allow override by subclasses
      return false if @icd_fields_all.none? { |field| ppat.death_data[field] =~ pattern }
      return true if @filter == 'all' # Return every match, not just new ones, even without NHS nos.

      super
    end
  end
end
