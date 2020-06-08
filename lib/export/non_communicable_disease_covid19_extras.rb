module Export
  # Extended version of non-communicable disease extract, to support COVID-19 excess mortality
  # comparisons
  # Export and de-pseudonymise monthly non-communicable diseases death data
  # Specification in plan.io #10954
  # Use filter='all' to extract all of a batch, instead of comparing against past extracts
  class NonCommunicableDiseaseCovid19Extras < NonCommunicableDiseaseMonthly
    def initialize(filename, e_type, ppats, filter = 'ncd')
      super
      @fields += (1..20).collect { |i| "icd_#{i}" } +
                 (1..20).collect { |i| "icdf_#{i}" } +
                 %w[cestrssr ceststay cestrss esttyped nhsind ctrypob pcdr pcdpod lsoar]
    end
  end
end
