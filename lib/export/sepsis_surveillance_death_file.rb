module Export
  # Plan.io 16561 / Project ID 81
  # NOTE: Requires linkage file
  class SepsisSurveillanceDeathFile < DeathFileSimple
    FIELDS = %w[
      icd9sc_icd10sc icd9scf_icd10scf icd9u_icd10u nhsno nhsnorss
      icd9uf_icd10uf doddy dodmt dodyr
    ].freeze

    SPECIAL = {
      nhsno: -> { (1..5).collect { |i| "nhsno_#{i}" } }
    }.freeze

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end
  end
end
