# Mixin for ActiveRecord models.
#
# Composes a scope/relation based on a provided `params` hash/object and is used as an
# interface/entry point for form based filtering.
#
# QUESTION: Is this the correct abstraction? Or reinventing wheels? Should searches be modelled
#           around specific ActiveModel classes? Time will likely tell.
#
# FIXME:    Add unit test coverage. Currently only indirectly tested via integration test(s).
#
# FIXME:    The `searchable_options` thing is a slight workaround for classes implementing their
#           own `search` method with  a differing method signature from the one provided/expected
#           here. See User#search as an example.
#
#
module Searchable
  extend ActiveSupport::Concern

  included do
    class_attribute :_searchable_attributes, default: []
    class_attribute :_searchable_options,    default: {}
  end

  class_methods do
    # Specifies an attribute or association that may be the target of a `search`, and the kind
    # of filtering that should be applied.
    def attr_searchable(attribute, type, **options)
      _searchable_options[attribute] = options if options.any?
      _searchable_attributes << [attribute, type]
    end

    def search(params)
      return all if params.blank?

      filters = search_filters(params)

      return all if filters.values.all?(&:none?)

      scope = unscoped

      if filters[:self].any?
        scope = filters[:self].inject(scope) do |chain, filter|
          chain.where(filter)
        end
      end

      if filters[:associated].any?
        scope = filters[:associated].inject(scope) do |chain, (association, search_params)|
          options = _searchable_options[association.name]
          args    = options && options[:kwargs] ? { params: search_params } : search_params

          chain.joins(association.name).merge(association.klass.search(args))
        end
      end

      where(id: scope)
    end

    private

    def search_filters(params)
      filters = { self: [], associated: [] }

      _searchable_attributes.each_with_object(filters) do |(attribute, filter_type), memo|
        target = filter_type == :association_filter ? :associated : :self
        filter = send(filter_type, attribute, params[attribute])

        memo[target].push(filter) if filter

        memo
      end
    end

    # Use standard ActiveRecord querying
    def default_filter(field, value)
      return unless field && value
      return if value.blank?

      { field => value }
    end

    # Allows for text search with LIKE predicates
    def text_filter(field, text)
      arel_table[field].matches("%#{text.strip}%") if text.present?
    end

    # Delegates a `search` to a related model
    def association_filter(association_name, search_params)
      return if search_params.blank?
      return unless association ||= reflect_on_association(association_name)

      [association, search_params]
    end
  end
end
