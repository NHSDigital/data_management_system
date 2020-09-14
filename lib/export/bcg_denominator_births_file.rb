module Export
  # BCG Denominator Births data
  # Specification in plan.io #24040
  class BcgDenominatorBirthsFile < BirthFileSimple
    # Country codes to extract
    # Generated using: csvcut -cCode bcg_denominator_country_codes.csv |tr "\n" " "
    COUNTRY_CODES = %w[
      004 012 024 031 050 204 064 068 072 076 096 854 108 132 116 120 140 148 156 344 446 178 384
      408 180 262 214 218 222 226 232 748 231 242 266 270 268 288 304 316 324 624 328 332 356 360
      368 398 404 296 417 418 426 430 434 440 450 454 458 466 584 478 583 496 504 508 104 516 520
      524 558 562 566 570 580 586 585 591 598 600 604 608 410 498 642 643 646 678 686 694 702 090
      706 710 728 144 729 762 764 626 795 798 800 804 834 860 548 862 704 887 894 716
    ].freeze

    def match_row?(ppat, _surveillance_code = nil)
      %w[ctrypobf ctrypobm].each do |field|
        val = ppat.birth_data.read_attribute(field)
        # Add missing leading zeros to country codes fields
        ppat.birth_data[field] = format('%03<val>d', val: val.to_i) if /\A[0-9]{1,2}\z/.match?(val)
      end
      unless %w[ctrypobf ctrypobm].any? do |field|
               COUNTRY_CODES.include?(ppat.birth_data.read_attribute(field))
             end
        return false
      end

      super
    end

    private

    # Fields to extract
    def fields
      %w[ccgpob ctypob ccg9pob ctyrm ctydrm ccgrm ctrypobm ctrypobf ccg9rm lsoarpob lsoarm]
    end
  end
end
