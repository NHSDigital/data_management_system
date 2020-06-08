module Export
  # Export and de-pseudonymise annual Hepatitis birth extract
  # Specification in plan.io #11230:
  # Immunisation team require all 2016 births.
  class HepatitisBirthsFile < BirthFileSimple
    private

    # Fields to extract
    def fields
      %w[loarpob namemaid dob dobm fnamm_1 pcdrm snamm snammcf mbisid ctrypobm loarm]
    end

    # Emit the value for a particular field, including extract-specific tweaks
    def extract_field(ppat, field)
      case field
      when 'dob', 'dobm' # Emit ISO dates, but label them DOB / DOBM
        return super(ppat, "#{field}_iso")
      end
      super(ppat, field)
    end
  end
end
