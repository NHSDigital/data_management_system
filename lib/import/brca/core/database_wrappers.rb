# require 'json'
# require 'possibly'
# require 'pry'
# require 'import/central_logger'
# # These wrappers contain genotypes, but provide comparisons at the level appropriate
# # to the described database table
# module Import
#   module Brca
#     module Core
#
#       class GenotypeWrapper
#         FIELD_MAPPING = { 'consultantcode' => 'practitionercode' } .freeze
#
#         # Convert the genotype representation to a hash containing the fields appropriate
#         # for the type of db record corresponding to the subclass. Field mappings allow
#         # for last-minute column renaming, and adds in raw representation so that
#         # essentially all the original information should end up in a db entry at some level
#         attr_reader :representative_genotype
#
#         def produce_record
#           (@field_names.map do |field|
#             [Maybe(FIELD_MAPPING[field]).or_else(field),
#             @representative_genotype.attribute_map[field]]
#           end).
#           to_h.
#           reject { |_, v| v.nil? }.
#           merge('raw_record' => JSON.generate(@representative_genotype.raw_record.raw_all))
#           # This intentionally forwards nils
#         end
#
#         def similar!(genotype)
#           @representative_genotype.similar_record(genotype, @field_names)
#         end
#       end
#
#       # Wrapper for genotype which compares fields present in the
#       # genetictest (molecular data) table
#       class GeneticTest < Import::Brca::Core::GenotypeWrapper
#         def initialize(genotype)
#           @representative_genotype = genotype
#           @field_names = Pseudo::MolecularData.column_names - %w[genetictestid
#                                                                  patientid
#                                                                  raw_record]
#         end
#
#         def produce_record
#           super().reject { |k, _| %w[localpatientidentifier organisationname_testresult].
#                                   include? k }
#           # standard_fields.merge({"genetictestresults" => resultRecords})
#         end
#
#         def similar!(genotype)
#           total_similarity = @representative_genotype.similar_record(genotype, @field_names)
#           partial_similarity = @representative_genotype.
#           similar_record(genotype, @field_names - ['karyotypingmethod'])
#           if total_similarity != partial_similarity
#             @representative_genotype.add_method(:multiple_methods) # "multiple testing methods"
#             genotype.add_method(:multiple_methods)
#             true
#           else
#             total_similarity
#           end
#         end
#       end
#
#       # Wrapper for genotype which compares fields present in the genetictestresult
#       # table
#       class GeneticTestResult < Import::Brca::Core::GenotypeWrapper
#         def initialize(genotype)
#           @representative_genotype = genotype
#           @field_names = Pseudo::GeneticTestResult.column_names - %w[genetictestresultid
#             genetictestid
#             report
#             raw_record]
#             @logger = Import::Log.get_logger
#           end
#
#           def similar!(genotype)
#             total_similarity = @representative_genotype.similar_record(genotype, @field_names)
#             partial_similarity = @representative_genotype.
#             similar_record(genotype,
#             @field_names - %w[teststatus
#               geneticaberrationtype])
#               if total_similarity != partial_similarity
#                 statuses = [@representative_genotype.get('teststatus'),
#                   genotype.get('teststatus')].
#                   reject(&:nil?).sort
#                   if statuses.empty?
#                     @logger.warn 'Cannot find any status to set on test result merge!'
#                   elsif statuses.size == 1
#                     @representative_genotype.add_status(statuses.first)
#                   elsif statuses.max < 3
#                     @representative_genotype.add_status(statuses.max)
#                   else
#                     @logger.warn "Cannot find consensus status for: #{statuses};"\
#                     "only setting #{statuses.first}"
#                     @representative_genotype.add_status(statuses.first)
#                   end
#                   @representative_genotype.
#                   add_aberration_type([@representative_genotype.get('geneticaberrationtype'),
#                     genotype.get('geneticaberrationtype')].
#                     reject(&:nil?).min)
#                     true
#                   else
#                     total_similarity
#                   end
#                 end
#
#                 def produce_record
#                   super()
#                   # standard_fields.merge({"geneticsequencevariants" => variantRecords})
#                 end
#               end
#
#               # Wrapper for genotype which compares fields present in the
#               # geneticsequencevariant table
#               class GeneticSequenceVariant < Import::Brca::Core::GenotypeWrapper
#                 def initialize(genotype)
#                   @representative_genotype = genotype
#                   @field_names = Pseudo::GeneticSequenceVariant.column_names -
#                   %w[geneticsequencevariantid genetictestresultid raw_record]
#                 end

#                 def produce_record
#                 # Should not produce a variant record unless there actually is a variant
#                   # if (@field_names -  ['variantpathclass']).all?
#                   # {|x| @representative_genotype.attribute_map[x].nil?}
#                   if @field_names.all? { |x| @representative_genotype.attribute_map[x].nil? }
#                     nil
#                   else
#                     super()
#                   end
#                 end
#
#                 def similar!(genotype)
#                   @representative_genotype.similar_record(genotype, @field_names - ['age'])
#                 end
#               end
#
#             end
#           end
#         end
