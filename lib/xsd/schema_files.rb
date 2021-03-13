module Xsd
  # Methods that alter the build method in order to build split large xsd into multiple files
  class SchemaFiles
    # if dataset contains categories spit out to separate files
    # build datatypes to it's own file
    # build the first child entities of the Record entity as their own file
    attr_accessor :zipfile, :dataset, :dataset_version, :semver_version, :name, :components

    def initialize(version, zipfile = nil)
      @zipfile = zipfile
      @dataset_version = version
      @semver_version = version.semver_version
      @dataset = version.dataset
      @name = version.name
      @components = []

      build
    end

    def build
      @dataset_version.preloaded_descendants

      master_file
      xml_types_file
      record_entities_file
      category_files
      xml_files
    end

    def master_file
      components << Xsd::ConstituentParts::Master.new(dataset_version, zipfile)
    end

    def xml_types_file
      components << Xsd::ConstituentParts::XmlTypes.new(dataset_version, zipfile)
    end

    def record_entities_file
      dataset_version.immediate_child_entities_of_record.each do |entity|
        components << Xsd::ConstituentParts::RecordEntity.new(entity, zipfile)
      end
    end

    def category_files
      return if dataset_version.categories.blank?

      (dataset_version.categories - [dataset_version.core_category]).each do |category|
        components << Xsd::ConstituentParts::Category.new(category, zipfile)
      end
    end

    def xml_files
      components << Xsd::ConstituentParts::Example.new(dataset_version, :sample_items, zipfile)
      return if dataset_version.choices.blank?

      components << Xsd::ConstituentParts::Example.new(dataset_version, :sample_choices, zipfile)
    end
  end
end
