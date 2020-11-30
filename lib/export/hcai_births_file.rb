module Export
  # HCAI Births data
  # Specification in plan.io #21885
  # For sample file, extract only 2017Q1 births
  class HcaiBirthsFile < BirthFileSimple
    def match_row?(ppat, _surveillance_code = nil)
      # Optional filter_quarter environment variable can provide a list of quarters to extract
      # e.g. 1 for Q1, 123 for Q1+Q2+Q3
      # Note however that this may not work as expected, as e.g. 2019 birth registrations will
      # include some births from 2018Q4, and include a few much older ones too.
      if ENV['filter_quarter']
        filter = ENV['filter_quarter']
        ppat.unlock_demographics('', '', '', :match)
        return false unless filter.include?(extract_field(ppat, 'dob_yyyyq')[-1])
      end

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
  end
end
