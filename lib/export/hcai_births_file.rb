module Export
  # HCAI Births data
  # Specification in plan.io #21885
  # For sample file, extract only 2017Q1 births
  class HcaiBirthsFile < BirthFileSimple
    def match_row?(ppat, _surveillance_code = nil)
      ppat.unlock_demographics('', '', '', :export)
      return false unless '20171' == extract_field(ppat, 'dob_yyyyq') # 2017Q1 births only

      super
    end

    private

    # Fields to extract
    def fields
      %w[namemaid esttypeb ccg9pob pobt pcdpob nhsind cestrss lsoarpob loarpob hropob hautpob
         ctypob ccgpob addrmt nhsno snamch fnamchx_1 fnamch3 fnamch2 fnamch1] +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        (1..20).collect { |i| "icdpv_#{i}" } +
        %w[snammcf snamm snamf fnammx_1 fnamm_1 fnamfx_1 fnamf_1 pcdrm dob dobm dobf seccatm
           seccatf soc90m soc90f soc2km soc2kf empstm empstf empsecm empsecf ctrypobm ctrypobf
           durmar bthimar agemm agemf agebm agebf ward9m gor9rm ccg9rm wardrm stregrm
           lsoarm loarm hrorm hautrm gorrm ctyrm ctydrm ccgrm sex_statistical wigwo10 deathlab] +
        (1..5).collect { |i| "codfft_#{i}" } +
        (1..20).collect { |i| "cod10r_#{i}" } +
        %w[gestatn sbind multtype multbth dor birthwgt mbisid]
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refactor into BirthFile (with MaternitiesFile)
    def extract_field(ppat, field)
      case field
      when 'dob_yyyyq'
        dob = super(ppat, 'dob')
        return "#{dob[0..3]}#{(dob[4..5].to_i + 2) / 3}"
      end
      super
    end
  end
end
