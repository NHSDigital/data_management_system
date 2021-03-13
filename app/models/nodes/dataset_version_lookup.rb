# Version for a dataset
module Nodes
  # builds a lookup that can be used when generating xsd
  class DatasetVersionLookup
    def self.lookup(dataset_version, xsd_type, name, category)
      @cache ||= build_lookup(dataset_version)
      @cache.merge!(build_lookup(dataset_version)) if version_cache_built?(dataset_version)
      version_lookup = @cache[dataset_version.name][dataset_version.semver_version]
      version_lookup[:xsd_names][category][name][xsd_type]
    end

    def self.common?(dataset_version, name, category)
      @cache ||= build_lookup(dataset_version)
      @cache.merge!(build_lookup(dataset_version)) if version_cache_built?(dataset_version)
      version_lookup = @cache[dataset_version.name][dataset_version.semver_version]
      result = version_lookup[:xsd_names][category][name]
      result[:element_name] == result[:type_name]
    end

    def self.entity_for_category?(dataset_version, category, entity_name)
      @cache ||= build_lookup(dataset_version)
      @cache.merge!(build_lookup(dataset_version)) if version_cache_built?(dataset_version)
      version_lookup = @cache[dataset_version.name][dataset_version.semver_version]
      version_lookup[:xsd_names][category][entity_name].present?
    end

    # build reference instead of checking entity_and_children_contains_specific_items every time
    def self.build_lookup(dataset_version)
      # build common
      lookup = {}
      lookup[dataset_version.name] = { dataset_version.semver_version => { xsd_names: {},
                                                                           entity_items: {} } }
      all_categories(dataset_version).each do |category|
        lookup[dataset_version.name][dataset_version.semver_version][:xsd_names][category] = {}
        dataset_version.preloaded_entities.each_with_object({}) do |entity, entity_lookup|
          next unless entity.node_for_category?(category)
          entity_lookup[entity.name] = { element_name: entity.xsd_element_name,
                                         type_name: entity.xsd_type_name(category) }
          dataset = dataset_version.name
          ver = dataset_version.semver_version
          lookup[dataset][ver][:xsd_names][category].merge!(entity_lookup)
        end
      end
      lookup
    end

    def self.all_categories(dataset_version)
      dataset_version.categories.blank? ? [nil] : dataset_version.categories.map(&:name) + [nil]
    end

    def self.version_cache_built?(dataset_version)
      return true if @cache[dataset_version.name].nil?
      @cache[dataset_version.name][dataset_version.semver_version].nil?
    end
  end
end
