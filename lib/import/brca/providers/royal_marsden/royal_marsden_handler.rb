require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module RoyalMarsden
        # BRCA importer for Royal Marsden Trust
        class RoyalMarsdenHandler < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age consultantcode servicereportidentifier providercode
                                   authoriseddate requesteddate practitionercode genomicchange
                                   specimentype].freeze

          TEST_SCOPE_MAP = { 'full gene' => :full_screen,
                             'specific mutation' => :targeted_mutation }.freeze
          VARIANT_PATH_CLASS = { 'pathogenic mutation' => 5,
                                 '1a' => 5,
                                 '1b' => 4,
                                 'variant of uncertain significance' => 3,
                                 'variant requiring evaluation' => 3,
                                 '2a' => 1,
                                 '2b' => 2,
                                 '2c' => 3,
                                 'variant' => 2 }.freeze

          TEST_TYPE_MAP = { 'affected' => :diagnostic,
                            'unaffected' => :predictive }.freeze

          CDNA_REGEX_PROT = /c\.(?<cdna>.+)(?=(?<separtors>_|;.)p\.(?<impact>.+))/i.freeze
          CDNA_REGEX_NOPROT = /c\.(?<cdna>.+)/i.freeze
          DEL_DUP_REGEX = /(?<deldup>Deletion|Duplication)\sexon(?<s>s)?\s(?<exon>\d+(?<d>-\d+)?)|
                           exon(?<s>s)?\s(?<exon>\d+(?<d>-\d+)?)
                           \s(?<deldup>Deletion|Duplication)/ix.freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            process_varpathclass(genotype, record)
            process_teststatus(genotype, record)
            process_variant(genotype, record)
            process_large_deldup(genotype, record)
            process_test_scope(genotype, record)
            process_test_type(genotype, record)
            add_organisationcode_testresult(genotype)
            process_gene(genotype, record)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '696L0'
          end

          def process_gene(genotype, record)
            gene = record.mapped_fields['gene'].to_i
            case gene
            when Integer
              if (7..8).cover? gene
                genotype.add_gene(record.mapped_fields['gene'].to_i)
                @logger.debug 'SUCCESSFUL gene parse for:' \
                              "#{record.mapped_fields['gene'].to_i}"
              else
                @logger.debug 'FAILED gene parse for: ' \
                              "#{record.mapped_fields['gene'].to_i}"
              end
            end
          end

          def process_varpathclass(genotype, record)
            # return if record.raw_fields['variantpathclass'].nil?
            if record.raw_fields['variantpathclass'].nil?
              @logger.debug 'NO VARIANT PATHCLASS DETECTED'
              return
            end
            varpathclass = record.raw_fields['variantpathclass'].downcase.strip
            # unless record.raw_fields['variantpathclass'].nil?
            # if varpathclass.present? && VARIANT_PATH_CLASS[varpathclass]
            return unless varpathclass.present? && VARIANT_PATH_CLASS[varpathclass]

            genotype.add_variant_class(VARIANT_PATH_CLASS[varpathclass.downcase])
          end

          def process_teststatus(genotype, record)
            if record.raw_fields['teststatus'].nil?
              @logger.debug 'UNABLE TO DETERMINE TESTSTATUS'
              return
            end

            teststatus = record.raw_fields['teststatus']
            # unless record.raw_fields['teststatus'].nil?
            if normal_test?(teststatus)
              genotype.add_status(1)
            elsif failed_test?(teststatus)
              genotype.add_status(9)
            elsif positive_test?(teststatus)
              genotype.add_status(2)
            end
          end

          def process_variant(genotype, record)
            return @logger.debug('NO VARIANT DETECTED') if record.raw_fields['teststatus'].nil?

            variant = record.raw_fields['teststatus']
            if CDNA_REGEX_PROT.match(variant)
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              @logger.debug "SUCCESSFUL protein impact parse for: #{$LAST_MATCH_INFO[:impact]}"
            elsif CDNA_REGEX_NOPROT.match(variant)
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'NO VARIANT DETECTED'
            end
          end

          def process_test_scope(genotype, record)
            tscope = record.raw_fields['genetictestscope']
            genotype.add_test_scope(TEST_SCOPE_MAP[tscope.downcase.strip]) \
            unless tscope.nil?
          end

          def process_test_type(genotype, record)
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip]) \
            unless mtype.nil?
          end

          def process_large_deldup(genotype, record)
            if record.raw_fields['teststatus'].nil?
              @logger.debug 'NO VARIANT DETECTED'
              return
            end

            deldup = record.raw_fields['teststatus']
            return unless DEL_DUP_REGEX.match(deldup)

            genotype.add_variant_type(DEL_DUP_REGEX.match(deldup)[:deldup])
            genotype.add_exon_location(DEL_DUP_REGEX.match(deldup)[:exon])
          end

          def normal_test?(teststatus)
            %r{NO PATHOGENIC (VARIANT|DEL/DUP) IDENTIFIED}.match(teststatus) ||
              /non-pathogenic variant detected/.match(teststatus) ||
              /No mutation detected/.match(teststatus)
          end

          def failed_test?(teststatus)
            /Fail|Wrong/i.match(teststatus)
          end

          def positive_test?(teststatus)
            /c\..+/.match(teststatus) ||
              /Deletion*/.match(teststatus) ||
              /Duplication*/.match(teststatus) ||
              /Exon*/i.match(teststatus)
          end
        end
      end
    end
  end
end
