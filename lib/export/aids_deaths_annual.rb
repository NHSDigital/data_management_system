# Project 60. # plan.io 10270
# bundle exec rake export:death fname='AIDS_ANNUAL_2016_TEST.txt' original_filename="deaths/SUBSET MBIS_Deaths_Subset_2016_skip1.txt" klass=Export::AidsDeathsAnnual project_name='Annual ONS Deaths for HIV Surveillance' team_name='HIV and STI Department'
module Export
  class AidsDeathsAnnual < DeathFile
    SURVEILLANCE_CODES = { 'aids99' => /
                             ^(A\d{2}|B\d{2}|C\d{2}|D[0-8][0-9]|E[0-8][0-9]|(F0[1-9]|F[1-9][0-9])|
                               G\d{2}|H|I\d{4}|J\d{2}|(K0[0-8][0-9]|K9[0-5])|L\d{2}|M\d{2}|N\d{2}|
                               O0[0-9]|O9A|(P0[0-8][0-9]|P9[0-6])|Q\d{2}|R\d{2}|S\d{2}|
                               (T0[0-7][0-9]|T8[0-8])|V\d{2}|W\d{2}|X\d{2}|Y\d{2}|Z\d{2})
                           /x }.freeze

    def initialize(filename, e_type, ppats, filter = 'aids99')
      super
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w(icduf)
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w(icdu)  
    end

    # kL/MS From looking at previous code we believe the following project node names equate to:
    # icd9sc_icd10sc => icdsc icdscf
    # icd9uf_icd10uf => icdu icduf
    # kL/MS From looking at previous code we believe the following project node names equate to:
    # fnamdx => fnamdx_1 fnamdx_2
    # codt => codt_codfft which transforms to codfft in death_file.rb
    def fields
      %w[addrdt fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 certifer] +
      %w[icdsc icdscf icdu icduf] +
      %w[podt dod dob sex ctrypob occdt pobt corcertt dor] +
      (1..6).collect { |i| "codt_codfft_#{i}" } +
      (1..4).collect { |i| "occfft_#{i}" }
    end

    private

    def csv_options
      { col_sep: '|', row_sep: "\r\n" }
    end

    def match_row?(ppat, _surveillance_code = nil)
      return false unless ppat.death_data.dor >= '20010101'
      pattern = SURVEILLANCE_CODES[@filter]
      icd_fields = @icd_fields_f
      # Check only final codes, if any present, otherwise provisional codes
      icd_fields = @icd_fields if icd_fields.none? { |field| ppat.death_data.send(field).present? }
      return false if icd_fields.none? { |field| ppat.death_data.send(field) =~ pattern }
      true
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)

      ppat.unlock_demographics('', '', '', :export)
      fields.collect { |field| extract_field(ppat, field) }
    end
  end
end
