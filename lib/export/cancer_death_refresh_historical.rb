module Export
  # Export and de-pseudonymise weekly cancer death data
  # in order to efficiently refresh old death records on the cancer registration system.
  # (This duplicates logic from era/app/source_models/e_death_record.rb and other places
  #  to precompute field values in the ONS extract, and also to allow the EVENTID values
  #  to be correctly exported
  # Specification file: "Cancer Deaths Specification 03-15 2008.docx"
  class CancerDeathRefreshHistorical < CancerDeathWeekly
    # The following codes are acceptable but are not registered:
    # copied from era Tumour::NOT_REGISTERED
    NOT_REGISTERED = /D1.?|D2.?|D30.?|D31.?|D34.?|D350|D351|D355|D356|D357|D358|D359|D36.?|D5.?|D6.?|D7.?|D8.?/

    def initialize(filename, e_type, ppats, filter = 'new', ppatid_rowids: nil)
      super
      # Add extra fields
      @rawsource_fields = @fields
      @fields = ['eventid'] + @fields +
                %w[deathlocation postmortem rawsource sourcetype ons_placeofdeath birthdatebest]
    end

    def header_rows
      unmap = FIELD_MAP.invert
      [@fields.collect { |field| unmap.fetch(field, field) }.collect(&:upcase)]
    end

    private

    def extract_mapped(ppat, field)
      # Allow fields to be specified by their FIELD_MAP entry
      extract_field(ppat, FIELD_MAP.fetch(field, field))
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refactor with DelimitedFile, CancerMortalityFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'eventid'
        return @ppatid_rowids[ppat.id]
      when 'deathlocation'
        # cf. era EDeathRecord#build_event, UnifiedSources::Batch::Preprocessor:CreateDeathRecord
        # and UnifiedSources::Batch::Preprocessor::CreateNcdRecord
        deathlocation = death_location_code(ppat)
        return deathlocation.presence || 'X'
      when 'postmortem'
        return has_postmortem?(ppat) ? 'Y' : 'N' # cf. era EDeathRecord#build_event
      when 'rawsource'
        return rawsource_hash(ppat).to_yaml
      when 'sourcetype'
        return registerable_icd_codes(ppat).any? ? 'DCC' : 'DCN' # cf. era ECdRecord#build_event
      when 'ons_placeofdeath'
        return extract_field(ppat, 'podt')
      when 'birthdatebest'
        return extract_field(ppat, 'dob_iso')
      end
      # esourcemappings used to strip leading spaces
      # return super(ppat, field)&.to_s&.lstrip if FIELD_MAP.value?(field)
      super(ppat, field)
    end

    # Mostly identical to era EDeathRecord#death_location_code
    def death_location_code(ppat)
      # place_of_death = rawtext['placeofdeath']
      place_of_death = extract_mapped(ppat, 'placeofdeath')
      return if place_of_death.blank?
      return '2' if Regexp.new(place_of_death.squash).match(extract_mapped(ppat, 'address').squash)

      case place_of_death
      when /hospital|infirmary/i then '1'
      when /hospice/i then '3'
      when /nursing home/i then '4'
      when /sue ryder care|care centre|care home/i then '5'
      end
    end

    # Mostly identical to era EDeathRecord#has_postmortem?
    def has_postmortem?(ppat)
      # !rawtext['coronerscertificate'].blank? || !rawtext['coronersname'].blank? ||
      #   !rawtext['coronersarea'].blank?
      !extract_mapped(ppat, 'coronerscertificate').blank? ||
        !extract_mapped(ppat, 'coronersname').blank? ||
        !extract_mapped(ppat, 'coronersarea').blank?
    end

    def rawsource_hash(ppat)
      unmap = FIELD_MAP.invert
      @rawsource_fields.collect do |field|
        [unmap.fetch(field, field), extract_field(ppat, field).to_s]
      end.to_h
    end

    # Mostly identical to era EDeathRecord#all_icd_codes
    def all_icd_codes(ppat)
      [
        extract_mapped(ppat, 'ons_code1a'), extract_mapped(ppat, 'ons_code1b'),
        extract_mapped(ppat, 'ons_code1c'), extract_mapped(ppat, 'ons_code2'),
        extract_mapped(ppat, 'ons_code'),
        extract_mapped(ppat, 'deathcausecode_underlying'),
        extract_mapped(ppat, 'deathcausecode_significant')
      ].join(' ').split(/,| |;/).select{|code| !code.blank? }.uniq.sort
    end

    # Mostly identical to era EBaseRecord.is_icd_registered?
    def is_icd_registered?(code)
      clean_code = code.to_s.upcase.gsub(/\./, '').gsub(/(D|A|X)$/, '')
      ((clean_code[0, 1] == 'C' || clean_code[0, 1] == 'D') && !NOT_REGISTERED.match(clean_code))
    end

    # Mostly identical to era EDeathRecord#registerable_icd_codes
    def registerable_icd_codes(ppat)
      all_icd_codes(ppat).select { |code| is_icd_registered?(code) }
    end
  end
end
