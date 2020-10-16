require 'ndr_import/table'
require 'ndr_import/file/registry'
require 'json'
require 'pry'
require 'csv'

folder = File.expand_path('../', __dir__)
$LOAD_PATH.unshift(folder) unless $LOAD_PATH.include?(folder)

require 'core/brca_handler_mapper'
require 'import/central_logger'
require 'import/import_key'
require 'import/brca/utility/pseudonymised_file_wrapper'

module Import
  module Brca
    module Core
      # Carry the fields from .pseudo parsing until they are converted into
      # a proper genotype object
      class RawRecord
        REQUIRED_FIELDS = ['pseudo_id1',
                           'pseudo_id2',
                           # 'key_bundle',
                           'encrypted_demog',
                           'clinical.to_json',
                           'encrypted_rawtext_demog',
                           'rawtext_clinical.to_json'].freeze

        def initialize(field_map)
          # TODO: record validation
          @logger = Log.get_logger
          if REQUIRED_FIELDS.map { |x| field_map[x].nil? } .any?
            @logger.error 'Encountered record missing critical fields; '\
                          'processing may be wrong/incomplete:'
            field_map.each do |key, value|
              @logger.debug "\t#{key}: #{value}"
            end
          end
          @fields     = field_map
          @pseudo_id1 = field_map['pseudo_id1']
          @pseudo_id2 = field_map['pseudo_id2']
          @keys       = Maybe(field_map['key_bundle']).or_else('')
          @raw_text   = field_map['encrypted_rawtext_demog'] # TODO: include as a field with rawtext
          @raw_fields    = JSON.parse(field_map['rawtext_clinical.to_json'])
          @mapped_fields = JSON.parse(field_map['clinical.to_json'])
        end

        def raw_all
          if @raw_fields.is_a?(Array)
            @raw_fields.collect do |raw_field|
              raw_field.merge('encrypted_rawtext_demog' => @raw_text,
                              'encrypted_demog' => @fields['encrypted_demog'])
            end
          elsif @raw_fields.is_a?(Hash)
            @raw_fields.merge('encrypted_rawtext_demog' => @raw_text,
                              'encrypted_demog' => @fields['encrypted_demog'])
          end
        end

        def eql?(other)
          @pseudo_id1 == other.pseudo_id1 &&
            @pseudo_id2 == other.pseudo_id2
          # @keys       == other.keys
        end

        def hash
          # (@pseudo_id1 + @pseudo_id2 + @keys).hash # include key field
          (@pseudo_id1 + @pseudo_id2).hash # include key field
        end

        attr_reader :pseudo_id1
        attr_reader :pseudo_id2
        attr_reader :raw_fields
        attr_reader :mapped_fields
        attr_reader :raw_text
        attr_reader :keys
      end
    end
  end
end
