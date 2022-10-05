require 'possibly'
require 'pry'

module Import
  module Colorectal
    module Providers
      module RoyalMarsden
        # Royal Marsden Colorectal Importer
        class RoyalMarsdenHandlerColorectal < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate practitionercode genomicchange
                                        specimentype].freeze


                                        
          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11|
                                                NTHL1)/xi . freeze # Added by Francesco

          TEST_SCOPE_MAP_COLO_COLO = { 'full gene' => :full_screen,
                                       'specific mutation' => :targeted_mutation } .freeze

          VARIANT_PATH_CLASS_COLO = { 'pathogenic mutation' => 5,
                                      '1a' => 5,
                                      '1b' => 4,
                                      'variant of uncertain significance' => 3,
                                      'variant requiring evaluation' => 3,
                                      '2a' => 1,
                                      '2b' => 2,
                                      '2c' => 3,
                                      'variant' => 2 } .freeze

          TEST_TYPE_MAP_COLO = { 'affected' => :diagnostic,
                                 'unaffected' => :predictive } .freeze

          CDNA_REGEX_PROT = /c\.(?<cdna>.+)(?=_p\.(?<impact>.+))/i .freeze
          CDNA_REGEX_NOPROT = /c\.(?<cdna>.+)/i .freeze
          DEL_DUP_REGEX = /(?<deldup>(Deletion|Duplication)) exon(s)? (?<exon>[\d]+(-[\d]+)?)|exon(s)? (?<exon>[\d]+(-[\d]+)?) (?<deldup>(Deletion|Duplication))/i .freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            process_varpathclass(genocolorectal, record)
            process_teststatus(genocolorectal, record)
            process_variant(genocolorectal, record)
            process_large_deldup(genocolorectal, record)
            process_test_scope(genocolorectal, record)
            process_test_type(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            res = process_gene(genocolorectal, record)# Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '696L0'
          end

          def process_gene(genocolorectal, record)
            genotypes = []
            genes = record.raw_fields['gene']
            if COLORECTAL_GENES_REGEX.match(genes)
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              @successful_gene_counter += 1
              genotypes.append(genocolorectal)
            else @logger.debug 'NOT A COLORECTAL/LYNCH/MMR RECORD'
            end
            genotypes
          end
          
          def process_varpathclass(genocolorectal, record)
            varpathclass = record.raw_fields['variantpathclass'].downcase.strip unless record.raw_fields['variantpathclass'].nil?

            if !varpathclass.nil? && !varpathclass.empty? && VARIANT_PATH_CLASS_COLO[varpathclass]
              genocolorectal.add_variant_class(VARIANT_PATH_CLASS_COLO[varpathclass.downcase])
            else
              @logger.debug 'NO VARIANTPATHCLASS DETECTED'
            end
          end

          def process_teststatus(genocolorectal, record)
            teststatus = record.raw_fields['teststatus'] unless record.raw_fields['teststatus'].nil?
            if /NO PATHOGENIC (VARIANT|DEL\/DUP) IDENTIFIED/.match(teststatus) ||
               /non-pathogenic variant detected/.match(teststatus) ||
               /No mutation detected/.match(teststatus)
              genocolorectal.add_status(1)
            elsif /Fail/i.match(teststatus)
              genocolorectal.add_status(9)
            elsif /c\..+/.match(teststatus) ||
                  /Deletion*/.match(teststatus) ||
                  /Duplication*/.match(teststatus) ||
                  /Exon*/i.match(teststatus)
                  genocolorectal.add_status(2)
            else
              @logger.debug 'UNABLE TO DETERMINE TESTSTATUS'
            end
          end

          def process_variant(genocolorectal, record)
            variant = record.raw_fields['teststatus'] unless record.raw_fields['teststatus'].nil?
            if CDNA_REGEX_PROT.match(variant)
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
            elsif CDNA_REGEX_NOPROT.match(variant)
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'NO VARIANT DETECTED'
            end
          end

          def process_test_scope(genocolorectal, record)
            tscope = record.raw_fields['genetictestscope']
            genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO_COLO[tscope.downcase.strip]) \
            unless tscope.nil?
          end

          def process_test_type(genocolorectal, record)
            mtype = record.raw_fields['moleculartestingtype']
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype.downcase.strip]) \
            unless mtype.nil?
          end

          def process_large_deldup(genocolorectal, record)
            deldup = record.raw_fields['teststatus'] unless record.raw_fields['teststatus'].nil?
            if DEL_DUP_REGEX.match(deldup)
              genocolorectal.add_variant_type($LAST_MATCH_INFO[:deldup])
              genocolorectal.add_exon_location($LAST_MATCH_INFO[:exon])
            end
          end
        end
      end
    end
  end
end
