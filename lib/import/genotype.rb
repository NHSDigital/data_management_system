require 'date'
require 'possibly'
#require_relative 'central_logger'
require_relative 'amino_acids'
module Import
  # This class forms the core intermediary between raw records coming in, and formatted records
  # ready for database inseration. As field values are added, the inseration methods attempt
  # to convert the field values into the codes used by the schema. Roughly speaking, each
  # Genotype object would compare to a SequenceVariant level record, if all tests (including
  # negative ones)produced sequence variants.
  # However, each genotype also contains all the information available about test and result
  # level fields, so that the storage processor can match and create the appropriate tables
  class Genotype
    include AminoAcids
    def initialize(raw_record, attribute_map = {})
      @pseudo_id1 = raw_record.pseudo_id1
      @pseudo_id2 = raw_record.pseudo_id2
      @raw_record = raw_record
      @attribute_map = attribute_map
      @logger = Log.get_logger
    end

    # --------------------- Schema code mapping tables --------------------------

    TYPING_METHOD_MAP = { 'mlpa' => 15,
                          'seq' => 17, # TODO: both as NGS?
                          'ngs' => 17 } .freeze

    VARIANT_CLASS_MAP = { '3a' => 9,
                          'deleterious' => 5,
                          'pathogenic' => 5,
                          'likely deleterious' => 4,
                          'likely pathogenic' => 4,
                          'unknown' => 3,
                          'unclassified variant' => 3,
                          'vus' => 3,
                          'likely benign' => 2,
                          'normal' => nil, # Useful for non-variants
                          'non-pathological variant' => 1,
                          'benign' => 1 } .freeze

    VARIANT_IMPACT_MAP = { 'missense' => 1,
                           'nonsense' => 2,
                           'frameshift' => 6 } .freeze

    TESTING_TYPE_MAP = { 'askhenazi pre-screen' => nil,
                         'diagnostic' => 1,
                         'diagnostic test' => 1,
                         'diagnostic testing' => 1,
                         'mutation screening' => 1,
                         'confirmation' => 1,
                         'diag - symptoms' => 1,
                         'diagnosis' => 1,
                         'diagnosis (2)' => 1,
                         'brca mainstreaming' => 1,
                         'mainstreaming test' => 1,
                         'predictive' => 2,
                         'predictive testing' => 2,
                         'presymptomatic test' => 2,
                         'presymptomatic' => 2,
                         'presymptomatic mlpa' => 2,
                         'predictive test' => 2,
                         'breast cancer predictives' => 2,
                         'prenatal' => 3,
                         'prenatal diagnosis' => 3 } .freeze

    GENOME_BUILD_MAP = { 10 => 1,
                         11 => 2,
                         12 => 3,
                         13 => 4,
                         15 => 5,
                         16 => 6,
                         17 => 7,
                         18 => 8,
                         19 => 9,
                         38 => 10 } .freeze

    SPECIMEN_TYPE_MAP = {
      'dna' => 12,
      'blood' => 5,
      'wax embedded' => 20,
      'biopsy' => 20,
      'mouthwash' => 10,
      'saliva' => 10
    }.merge(Hash[(1..24).map { |x| [x.to_s, x] }]).freeze

    BRCA_REGEX = /(?:b)?(?:r)?(?:c)?(?:a)?(1|2)/i.freeze

    # ------------------------ Interogators ------------------------------
    def positive?
      cur_status = @attribute_map['teststatus'] # .map { |x| x == 6 }.
      @logger.warn 'WARNING: reporting status, but none set' if cur_status.nil?
      Maybe(cur_status == 2).or_else(false)
    end

    def full_screen?
      scope = @attribute_map['genetictestscope']
      return nil unless scope

      scope == 'Full screen BRCA1 and BRCA2'
    end

    def reportidentifier
      id = @attribute_map['servicereportidentifier']
      log.warn 'Could not provide identifier' if id.nil?
      Maybe(id).or_else('none_provided')
    end

    # def other_gene
    #   gene = @attribute_map['gene']
    #   return nil unless gene
    #
    #   case gene
    #   when 8 then 7
    #   when 7 then 8
    #   else
    #     @logger.warn "Something very wrong, trying to get gene opposite of: #{gene}"
    #   end
    # end

    def get(key)
      @attribute_map[key]
    end

    attr_reader :attribute_map
    attr_reader :pseudo_id1
    attr_reader :pseudo_id2
    attr_reader :raw_record

    # ------------------------- Comparators ------------------------------
    def similar_record(other_genotype, field_list, strict = true)
      # Establish that it is the same patient
      id_comp = @raw_record.pseudo_id1 == other_genotype.pseudo_id1 &&
                @raw_record.pseudo_id2 == other_genotype.pseudo_id2

      # Ensure equality in all provided fields TODO - nil handling?
      field_list.all? do |key|
        this_value = @attribute_map[key]
        other_value = other_genotype.get(key)
        if strict
          (this_value == other_value)
        else
          (this_value == other_value) || this_value.nil? || other_value.nil?
        end
      end && id_comp
    end

    def merge(other_genotype)
      raise("Merge not implemented! Cannot merge with #{other_genotype}")
    end

    # ------------------------- Utilities --------------------------------
    def to_s
      "#{@raw_record.Pseudo_id1}\n#{@raw_record.pseudo_id2}\n#{@attribute_map}"
    end

    # -------------------------- Setters ---------------------------------
    def add_method(method_string)
      return if method_string.nil? # || method_string.empty?

      case method_string
      when :multiple_methods # TODO: could move these into a map
        @attribute_map['karyotypingmethod'] = 7
      when :ngs
        @attribute_map['karyotypingmethod'] = 17
      when :sanger
        @attribute_map['karyotypingmethod'] = 16
      when String
        return if method_string.empty?

        if TYPING_METHOD_MAP[method_string.strip.downcase]
          @attribute_map['karyotypingmethod'] = TYPING_METHOD_MAP[method_string.downcase]
        else
          @logger.error "Invalid typing method provided: #{method_string}"
        end
      when Nil
        @logger.error 'NULL typing method provided' # Do nothing
      end
    end

    def add_geneticinheritance(inheritance_string)
      return if inheritance_string.blank?

      case inheritance_string
      when :mosaic
        @attribute_map['geneticinheritance'] = 6
      else
        @logger.warn "Unable to add geneticinheritance: #{inheritance_string}"
      end
    end

#     def add_gene(brca_input)
#       case brca_input
#       when Integer
#         gene_integer_input(brca_input)
#       when String
#         gene_string_input(brca_input)
#       when nil
# #            @logger.error 'Null input for gene'
#       else
#         @logger.error "Bad input type given for brca1/2 extraction: #{brca_input}"
#       end
#     end
#
#     def gene_integer_input(brca_input)
#       if (1..2).cover? brca_input
#         # BRCA 1 and 2 map to gene codes 7 and 8
#         @attribute_map['gene'] = brca_input + 6
#       elsif (7..8).cover? brca_input
#         @attribute_map['gene'] = brca_input
#       else
#         @logger.error 'Invalid gene reference given to addGene; ' \
#         "needs 1 or 2, given: #{brca_input}"
#       end
#     end
#
#     def gene_string_input(brca_input)
#       return if brca_input.empty?
#
#       match_num = brca_input.strip.scan(BRCA_REGEX).size
#       if match_num > 1
#         @logger.debug 'Bad input string (too many genes) given for brca1/2'\
#         " extraction: #{brca_input}"
#       elsif match_num.zero?
#         @logger.debug 'Bad input string (no detected genes) given for brca1/2'\
#         " extraction: #{brca_input}"
#       else
#         if brca_input.include? '/'
#           @logger.debug 'WARNING: string provided for gene extraction contains a'\
#           "slash, possible multi-gene error: #{brca_input}"
#         end
#         gene_regex_input(brca_input)
#       end
#     end

    # def gene_regex_input(brca_input)
    #   case BRCA_REGEX.match(brca_input.strip)
    #   when nil
    #     @logger.debug "Bad input string given for brca1/2 extraction: #{brca_input}"
    #   else
    #     add_gene($LAST_MATCH_INFO[1].to_i)
    #   end
    # end

    def add_gene_location(location_string)
      return if location_string.nil?

      # Attempt to standardize the c. notation as much as possible
      common_formatted = location_string.
                         tr(' ', '').
                         downcase.
                         chomp(',')
      common_formatted.tr!('atcg', 'ATCG')
      common_formatted.gsub!(/C\./, 'c.')
      common_formatted = 'c.' + common_formatted unless common_formatted.starts_with?('c.')
      # common_formatted = common_formatted.
      common_formatted.gsub!(/del[ATCG]+/, 'del') # Attempt to standarize format for matching
      @attribute_map['codingdnasequencechange'] = common_formatted
      add_aberration_type(:mutation)
      add_variant_type(location_string)
      add_status(2)
    end

    def add_aberration_type(ab_type)
      case ab_type
      when 6, 7
        @attribute_map['geneticaberrationtype'] = ab_type
      when :mutation
        @attribute_map['geneticaberrationtype'] = 6
      when :normal
        @attribute_map['geneticaberrationtype'] = 7
      else
        @logger.warn "Unable to process geneticaberrationtype: #{ab_type}"
      end
    end

    def add_variant_type(location)
      return nil unless location.is_a? String

      if location.include?('delins') || location.include?('indel')
        @attribute_map['sequencevarianttype'] = 6
      elsif location.include? 'dup'
        @attribute_map['sequencevarianttype'] = 4
      elsif location.include? 'del'
        @attribute_map['sequencevarianttype'] = 3
      elsif location.include? '>'
        @attribute_map['sequencevarianttype'] = 1
      elsif location.include? 'ins'
        @attribute_map['sequencevarianttype'] = 2
      else @attribute_map['sequencevarianttype'] = 10
      end
    end

    def add_exon_location(location_string)
      # TODO: string shape validation
      return if location_string.blank?

      @attribute_map['exonintroncodonnumber'] = location_string.downcase.strip.
                                                gsub(/[[:space:]]/, '').
                                                gsub(/to/, '-')
      add_aberration_type(:mutation)
      add_status(2)
      @attribute_map['variantlocation'] = 1
    end

    # TODO: for below method - input form validation
    def add_protein_impact(protein_string)
      return if protein_string.nil?

      common_formatted = protein_string.
                         strip.
                         tr(' ', '').
                         tr('(', '').
                         tr(')', '').
                         gsub(/\*/, 'Ter').
                         downcase
      triplet_codes.each do |code|
        common_formatted.gsub!(/#{code.downcase}/, code.capitalize)
      end
      common_formatted = 'p.' + common_formatted unless common_formatted.starts_with?('p.')
      @attribute_map['proteinimpact'] = common_formatted unless common_formatted.empty?
    end

    # Zygosity is in the scheme at both the Result and Variant level. Here we set it
    # at the variant level, as we could conceivably have multiple variants for a single
    # test, each of which *could* have different zygosity
    def add_zygosity(zygosity)
      case zygosity
      when String then
        zygosity_downcase = zygosity.downcase
        if zygosity_downcase.include? 'het'
          @attribute_map['variantgenotype'] = 1
        elsif zygosity_downcase.include? 'homo'
          @attribute_map['variantgenotype'] = 2
        else
          @logger.debug "Cannot determine zygosity; perhaps should be complex? #{zygosity}"
        end
      when Integer then
        if (1..2).cover? zygosity
          @attribute_map['variantgenotype'] = zygosity
        else
          @logger.error "Bad integer value (out of range) given for zygosity: #{zygosity}"
        end
      else
        @logger.error("Bad input type given for zygosity: #{zygosity}")
      end
    end

    def add_chromosome_number(num)
      raise("Chromsome number not implemented! Received: #{num}")
    end

    def add_specimen_type(specimen_type)
      if specimen_type.is_a?(Integer) && (1..24).cover?(specimen_type)
        @attribute_map['specimentype'] = specimen_type
      elsif specimen_type.is_a?(String) && SPECIMEN_TYPE_MAP[specimen_type.downcase]
        @attribute_map['specimentype'] = SPECIMEN_TYPE_MAP[specimen_type.downcase]
      elsif specimen_type.nil?
      else
        @logger.warn("Bad/unknown specimen type given: #{specimen_type}; not recording")
      end
    end

    def add_variant_impact(impact)
      case impact
      when String then
        if VARIANT_IMPACT_MAP[impact]
          @attribute_map['variantimpact'] = VARIANT_IMPACT_MAP[impact]
        else
          @logger.error('Bad input string given to addVariantImpact; '\
          "value: #{impact}; not present in mapping")
        end
      when Integer then
        if (1..11).cover? impact
          @attribute_map['variantimpact'] = impact
        else
          @logger.error('Bad input value given to addVariantImpact; '\
          "value: #{impact} out of valid integer range")
        end
      when nil then
        @logger.error('Variant Impact field is null')
        # Do nothing
      else
        @logger.error('Bad input type given to addVariantImpact;'\
        "value: #{impact} of type #{impact.class}")
      end
    end

    def add_variant_class(variant)
      if variant.is_a?(Integer) && variant >= 1 && variant <= 10
        @attribute_map['variantpathclass'] = variant
      elsif variant.is_a?(String)
        if VARIANT_CLASS_MAP[variant.downcase.strip]
          @attribute_map['variantpathclass'] = VARIANT_CLASS_MAP[variant.downcase.strip]
        else
          @logger.warn "Bad variant class string given: #{variant}; cannot process"
        end
      else
        @logger.error("Input: #{variant} given for variant class of improper"\
        "type (#{variant.class}), or out of range")
      end
    end

    def add_molecular_testing_type(molecular_testing_type_string)
      if molecular_testing_type_string.downcase.include? 'predictive'
        @attribute_map['moleculartestingtype'] = 2
      elsif molecular_testing_type_string.downcase.include? 'diagnostic'
        @attribute_map['moleculartestingtype'] = 1
        # else
        # @logger.debug "WARNING: could not extract molecular testing type from:
        # {molecular_testing_type_string}"
        # No point in logging, as this fails often
      end
    end

    def add_molecular_testing_type_strict(test_string)
      return if test_string.nil?

      case test_string
      when :diagnostic
        @attribute_map['moleculartestingtype'] = 1
      when :predictive
        @attribute_map['moleculartestingtype'] = 2
      when :carrier
        @attribute_map['moleculartestingtype'] = 3
      when :prenatal
        @attribute_map['moleculartestingtype'] = 4
      when String
        clean = test_string.downcase.strip
        @attribute_map['moleculartestingtype'] = TESTING_TYPE_MAP[clean] if
                                                 TESTING_TYPE_MAP[clean]
      else
        @logger.warn "Bad value given for molcular testing type: #{test_string}"
      end
    end

    def add_status(status)
      case status
      when String then
        case status.downcase.strip
        when 'pos'
          @attribute_map['teststatus'] = 2 # TODO: confirm this assignment
        when 'neg'
          @attribute_map['teststatus'] = 1 # TODO: confirm this assignment
        else
          @logger.error("Bad status: #{status} given; unable to apply")
        end
      when Integer then
        if (1..10).cover? status
          @attribute_map['teststatus'] = status
        else
          @logger.error("Bad integer value given for status (out of valid range): #{status}")
        end
      when :normal
        @attribute_map['teststatus'] = 1
      when :negative # added recently by Francesco
        @attribute_map['teststatus'] = 1 # added recently by Francesco
      when :positive # added recently by Francesco
        @attribute_map['teststatus'] = 2 # added recently by Francesco
      when :failed # added recently by Francesco
        @attribute_map['teststatus'] = 9 # added recently by Francesco
      when :unknown
        @attribute_map['teststatus'] = 4# added recently by Francesco
      else
        @logger.error("Bad type given for addStatus; value: #{status} of type: #{status.class}")
      end
    end

    def set_negative
      @attribute_map['teststatus'] = 1 # TODO: confirm this assignment
    end

    def add_received_date(date_string)
      return if date_string.blank?

      parsed = DateTime.parse(date_string).in_time_zone
      @attribute_map['receiveddate'] = parsed if parsed
      # TODO: figure out best form for DB
    end

    def add_requested_date(date_string)
      if date_string.empty?
        @logger.warn 'Attempt to add requested date from empty string'
        return
      end
      parsed = DateTime.parse(date_string).in_time_zone
      @attribute_map['requesteddate'] = parsed if parsed
      # TODO: figure out best form for DB
    end

    def add_provider_name(name)
      if name.empty?
        @logger.warn 'Attempt to set provider name to empty string; ignoring'
      else
        @attribute_map['providername'] = name # TODO: validation?
      end
    end

    def add_genome_build(build)
      return if build.blank?

      build_match = GENOME_BUILD_MAP[build]
      if build_match
        @attribute_map['humangenomebuild'] = build_match
      else
        @logger.warn "Bad value given for human genome build: #{build}"
      end
    end

    def add_raw_genomic_change(change)
      return if change.blank?

      @attribute_map['genomicchange'] = change
    end

    def add_parsed_genomic_change(chr_num, gchange)
      return if gchange.blank?

      @attribute_map['genomicchange'] = "#{chr_num}:#{gchange}"
    end

    def add_typed_location(extracted)
      case extracted
      when Import::ExtractionUtilities::ExactLocation
        add_gene_location(extracted.cdna)
        add_protein_impact(extracted.protein)
        0
      when Import::ExtractionUtilities::ExonLocation
        add_exon_location(extracted.exon)
        add_variant_type(extracted.mods)
        0
      when Import::ExtractionUtilities::ParseFailure
        @logger.warn "Could not parse genotype: #{extracted.raw}"
        1
      else
        @logger.warn "Something very wrong, not even a parse failure: #{extracted.raw}"
        1
      end
    end

    def add_referencetranscriptid(referencetranscriptid)
      return if referencetranscriptid.blank?

      @attribute_map['referencetranscriptid'] = referencetranscriptid
    end

    def add_servicereportidentifier(identifier)
      return if identifier.blank?

      @attribute_map['servicereportidentifier'] = identifier
    end

    def add_passthrough_fields(mapped_fields,
                               raw_fields,
                               whitelist,
                               # TODO: not the best place for a default mapping to live
                               mapping = { 'consultantcode' => 'practitionercode' })

      [raw_fields, mapped_fields].each do |field_map|
        field_map.each do |key, value|
          next unless whitelist.include?(key)

          if @attribute_map.keys.include?(key) && !(mapped_fields.keys.include?(key) &&
            raw_fields.keys.include?(key))
            @logger.warn "Warning: overwriting value on passthrough: #{key}, #{value}"
          end
          @attribute_map[Maybe(mapping[key]).or_else(key)] = value
        end
      end
    end
  end
end
