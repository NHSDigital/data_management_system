module Export
  # Export and de-pseudonymise annual maternities death extract as quarterly files
  # Used by PHE / HIV team
  # Specification file: "Annual 2016 Maternities Specification.xlsx"
  class MaternitiesFile < BirthFile
    COLUMN_PATTERNS = [%w(sbind A1),
                       %w(agebm_band A1),
                       %w(ctrypobm A4),
                       %w(ctrypobm_phls A2),
                       %w(dob_yyyyq A5),
                       %w(cestrss A5),
                       %w(ctyrm A2),
                       %w(ctydrm A2),
                       %w(hautrm A3),
                       %w(hrorm A3),
                       %w(hautpob A3),
                       %w(hropob A3),
                       %w(blank A3),
                       %w(blank A3),
                       %w(blank A3),
                       %w(blank A3),
                       %w(blank A2),
                       %w(blank A2),
                       %w(ctrypobf A4),
                       %w(ctrypobf_phls A2)].freeze

    PHLS_CODES = {
      '01' => %w(840 985 124),
      '02' => %w(188 222 320 340 484 558 591),
      '03' => %w(032 068 076 152 170 218 238 600 604 740 858 862),
      # "BD006 - PHLS Maternities extract 008  Angela Preparation for M.pdf"
      # has 328 and 780 in both '03' and '04' but ONS output file maps these to '04'
      '04' => %w(192 214 312 332 474 530 531 534 535 999 630 850 092 052 084 988 328 388 780),
      '5a' => %w(800 404),
      '5b' => %w(024 204 072 854 108 120 132 140 148 174 178 262 226 231 266 270 288 324 624 384
                 426 430 450 454 466 478 480 508 516 562 566 646 654 678 686 690 694 706 710 736
                 728 729 748 834 768 180 894 716 232),
      '06' => %w(048 400 414 422 512 634 682 784 887 012 818 364 368 434 504 760 788 792),
      '07' => %w(050 356 524 586),
      '08' => %w(162 242 296 598 882 090 776 548 096 104 116 156 158 626 360 392 408 410 418 458
                 608 702 764 704 882
                 166 184 520 570 574 612 772 798 016 258 316 581 540 584 876),
      # 166, 184, 520, 570, 574, 612, 772, 798, 016, 258, 316, 581, 540, 584, 876 not in
      # "BD006 - PHLS Maternities extract 008  Angela Preparation for M.pdf", but 184, 016, 258,
      # 316, 581, 540 all mapped to PHLS code '08' in sample file MEPH16{1,2,3,4}.TXT
      '09' => %w(036 554),
      # 010 not in "BD006 - PHLS Maternities extract 008  Angela Preparation for M.pdf"
      '10' => %w(727 931 020 040 056 208 921 246 250 276 292 300 831 352 372 380 832 438 442 470
                 833 492 528 922 578 620 923 911 913 752 756 924),
      # 674 not in "BD006 - PHLS Maternities extract 008  Angela Preparation for M.pdf"
      '11' => %w(008 051 031 112 070 100 191 203 233 268 348 398 417 428 440 807 498 616 642 643
                 972 688 499 951 974 703 705 762 795 804 860)
    }.freeze

    QUARTER_NAMES = { '1' => 'ONE', '2' => 'TWO', '3' => 'THREE', '4' => 'FOUR' }.freeze

    def initialize(filename, e_type, ppats, filter)
      super
      @col_pattern = COLUMN_PATTERNS
      # Historic file has 54 blank spaces at the end of each row
      @col_pattern += [%w(space1 A54)]
      @phls_lookup = {}
      PHLS_CODES.each { |k, vv| vv.each { |v| @phls_lookup[v] = k } }
    end

    # Export data to file, returns number of records emitted
    # Produces a fixed-width file, not a CSV file
    def export
      i = 0
      File.open(@filename, 'wb') do |outf|
        header_rows.each { |row| outf << row }
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        @ppats.includes(:birth_data, :ppatient_rawdata).send(meth) do |ppat|
          row = extract_row(ppat, i + 1)
          if row
            outf << row + "\r\n"
            i += 1
          end
        end
        # Print footer rows
        footer_rows(i).each { |row| outf << row + "\r\n" }
      end
      i
    end

    private

    def footer_rows(i)
      [["RECORDS EXTRACTED FOR QUARTER #{QUARTER_NAMES[@filter]} = #{i}"].pack('A110')]
    end

    # Does this row match the current extract
    # Records selected will have MATTAB = 1 (first birth per mother)
    def match_row?(ppat, _surveillance_code = nil)
      return false unless ppat.birth_data.mattab == 1
      ppat.unlock_demographics('', '', '', :match)
      @filter == extract_field(ppat, 'dob_yyyyq')[-1]
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      fields = @col_pattern.collect(&:first)
      pattern = @col_pattern.collect(&:last).join
      # Use Windows-1252 encoding for fixed width maternities export
      fields.collect { |field| extract_field(ppat, field).to_s.encode('windows-1252') }.
        pack(pattern)
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refactor into BirthFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'agebm_band'
        agebm = super(ppat, 'agebm')
        return '' unless agebm.present?
        return case agebm[0..1].to_i
               when 0..19 then 'A'
               when 20..24 then 'B'
               when 25..29 then 'C'
               when 30..34 then 'D'
               when 35..39 then 'E'
               when 40..44 then 'F'
               else 'G'
               end
      when 'ctrypobm_phls'
        return @phls_lookup[super(ppat, 'ctrypobm')]
      when 'ctrypobf_phls'
        return @phls_lookup[super(ppat, 'ctrypobf')]
      when 'dob_yyyyq'
        dob = super(ppat, 'dob')
        return "#{dob[0..3]}#{(dob[4..5].to_i + 2) / 3}"
      when 'space1'
        return ' '
      end
      val = super(ppat, field)
      val = val.gsub('"', '  ')[0..74] if val && val =~ /"/ # Double quotes to 2 spaces, <= 75 char
      val
    end
  end
end
