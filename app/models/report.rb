# Namespace and logical store for reports, to support an ActiveRecord-like access pattern.
module Report
  mattr_accessor :_list, default: {}.with_indifferent_access

  class << self
    def register(report)
      _list[report.model_name.element] = report
    end

    def all
      _list.values
    end

    def find(key)
      _list.fetch(key)
    end

    def each(&block)
      all.each(&block) # rubocop:disable Rails/FindEach
    end
    alias find_each each
  end
end

# Eager load all the definitions:
Rails.root.join('app/models/report').each_child do |file|
  # Ensure autoloading is aware of what we're doing:
  require_dependency file
end
