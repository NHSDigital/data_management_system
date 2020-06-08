module Export
  # Export and de-pseudonymise monthly / annual tuberculosis (TB) deaths
  # Specification: https://ncr.plan.io/issues/14398
  # and https://ncr.plan.io/issues/14407
  # Use filter='all' to get all TB records from a batch (including repeats)
  # or filter='new' to get only new TB records in a batch (excluding records sent before)
  # or filter='all_nhs' for all TB records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new TB records with NHS numbers (excl. such records sent before)
  class TbDeathMonthly < TbDeathCommon
    # Inclusion & Exclusion criteria for TB deaths:
    # All annual deaths where ONS coded death with active TB (ICD-10 A15-19) and TB sequelae
    # (ICD-10 B90.0- B90.9) from 2000 onwards for England and Wales
    SURVEILLANCE_CODES = { 'tb' => /^(A1[5-9]|B90)/ }.freeze # New TB deaths

    def initialize(filename, e_type, ppats, filter = 'new', ppatid_rowids: nil)
      super
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w[icduf]
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w[icdu]
      @icd_fields_all = @icd_fields_f + @icd_fields
    end

    private

    # Does this row match the current extract?
    def match_row?(ppat, _surveillance_code = nil)
      pattern = SURVEILLANCE_CODES['tb']
      return false if @icd_fields_all.none? { |field| ppat.death_data[field] =~ pattern }
      return true if @filter == 'all' # Return every match, not just new ones, even without NHS nos.
      super
    end
  end
end
