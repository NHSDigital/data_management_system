module Export
  # Export and de-pseudonymise annual KIT death extract
  # Specification file: "PHE K&IS BIRTHS 2016.pdf"
  class KitBirthsFile < BirthFileSimple
    private

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: true }
    end

    # Fields to extract
    def fields
      # Simple fields to extract, without special processing
      %w(dob agebm pcdrm hautrm hrorm gorrm ctyrm ctydrm wardrm cestrss esttypeb hautpob
         hropob dor sex_statistical birthwgt pcdind bthimar ctrypobm occ90m ctrypobf
         occ90f multtype mattab sbind) + (1..15).collect { |i| "icdpv_#{i}" } +
        (1..15).collect { |i| "cod10r_#{i}" } +
        %w(wigwo10 soc2kf soc2km ctyrma ctyrdma gorrma wardrma seccatf seccatm lsoarm)
      # Intentionally not in MBIS: pcdind occ90m occ90f ctyrma ctyrdma gorrma wardrma
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'gorrm'
        # Support move to LEDR data (2017-onwards), but still handle 2016 data sensibly
        return super(ppat, 'gor9rm') || super(ppat, field)
      end
      val = super(ppat, field)
      case field
      when 'ctrypobm', 'ctrypobf' # Country code tweak for annual birth extracts
        val = ' ' if val == '969'
      end
      val
    end
  end
end
